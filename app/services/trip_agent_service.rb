# Answers one message in a trip's assistant chat. The model never edits the itinerary
# itself: it calls propose_changes, which is validated here and saved as a pending
# TripAgentProposal for a member to apply.
class TripAgentService
    class AgentError < StandardError; end

    MAX_TOKENS = 16_000
    MAX_TOOL_ROUNDS = 5
    HISTORY_LIMIT = 30
    ACTIONS = %w[add update remove move update_day].freeze
    ITEM_ACTIONS = %w[update remove move].freeze

    NULLABLE_STRING = { type: [ "string", "null" ] }.freeze

    PROPOSE_CHANGES_TOOL = {
        name: "propose_changes",
        description: "Propose a set of itinerary changes for the group to review and apply. " \
                     "Nothing changes until a member applies them. Call this at most once per reply with the " \
                     "full set of changes; calling it again replaces the earlier proposal.",
        strict: true,
        input_schema: {
            type: "object",
            additionalProperties: false,
            required: [ "changes" ],
            properties: {
                changes: {
                    type: "array",
                    items: {
                        type: "object",
                        additionalProperties: false,
                        required: %w[action day_number item_id idea_card_id title notes scheduled_time address
                                     city accommodation_name accommodation_address summary],
                        properties: {
                            action: {
                                type: "string", enum: ACTIONS,
                                description: "add: new item on day_number. update: edit item_id in place. " \
                                             "remove: delete item_id. move: move item_id to day_number (and/or a new time). " \
                                             "update_day: change city or accommodation of day_number."
                            },
                            day_number: { type: "integer", description: "Target day. For update/remove, the item's current day." },
                            item_id: NULLABLE_STRING.merge(description: "Existing item id, required for update/remove/move."),
                            idea_card_id: NULLABLE_STRING.merge(description: "For add: id of a saved idea being scheduled, otherwise null."),
                            title: NULLABLE_STRING.merge(description: "For add/update: the activity or place name."),
                            notes: NULLABLE_STRING.merge(description: "For add/update: 1-2 short sentences with tips."),
                            scheduled_time: NULLABLE_STRING.merge(description: "HH:MM:SS for add, or for update/move when the time changes."),
                            address: NULLABLE_STRING.merge(description: "For add/update: real street address or 'Place, City, Country'."),
                            city: NULLABLE_STRING.merge(description: "For update_day only."),
                            accommodation_name: NULLABLE_STRING.merge(description: "For update_day only."),
                            accommodation_address: NULLABLE_STRING.merge(description: "For update_day only."),
                            summary: { type: "string", description: "One short line shown to the user, e.g. 'Lunch at Tsukiji Outer Market'." }
                        }
                    }
                }
            }
        }
    }.freeze

    INSTRUCTIONS = <<~PROMPT.freeze
    You are the trip assistant inside Itinify, a group trip planner. Several members of one trip share this
    chat; each user message starts with the name of the member who wrote it.

    You already have the full, current trip below: dates, members, preferences, every day and item with ids,
    and the saved ideas board. Never ask the user to explain their trip, dates, budget or what is planned.
    Work it out from the trip context. Only ask a question when the request is genuinely ambiguous and a
    reasonable default would be wrong.

    How you make changes:
    - Make targeted changes. Never rebuild or reshuffle the whole itinerary unless explicitly asked.
    - Use propose_changes for any change. Changes are only suggestions until a member applies them, so don't
      say they're done; say what you're suggesting.
    - Keep everything you don't need to touch exactly as it is.
    - Fit new items around what is already planned: sensible times, near that day's other stops or hotel,
      and within the trip's budget and pace.
    - Prefer the group's saved ideas when they fit (set idea_card_id).
    - Use real, specific places with addresses suitable for Google Maps.
    - For requests that only need an answer (e.g. "what are we doing Tuesday?"), just answer.

    After proposing, reply in 1-3 short sentences on what you suggested and why. The user sees the change list
    separately, so don't repeat every item. Use plain text or short markdown lists.
    PROMPT

    def initialize(trip, user, content)
        @trip = trip
        @user = user
        @content = content
        @proposed_changes = nil
    end

    # Returns [user_message, assistant_message]; nothing is saved if the model call fails
    def call
        reply_text = run_agent

        ActiveRecord::Base.transaction do
            user_message = @trip.trip_agent_messages.create!(role: "user", user: @user, content: @content)
            reply = @trip.trip_agent_messages.create!(role: "assistant", content: reply_text)
            if @proposed_changes.present?
                @trip.trip_agent_proposals.create!(trip_agent_message: reply, changes_list: @proposed_changes)
            end
            [ user_message, reply.reload ]
        end
    end

    private

    def client
        @client ||= Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    end

    def run_agent
        messages = history + [ { role: "user", content: "#{@user.name}: #{@content}" } ]
        texts = []

        MAX_TOOL_ROUNDS.times do
            response = create_message(messages)
            check_stop_reason!(response)
            texts.concat(response.content.select { |b| b.type == :text }.map(&:text))

            tool_uses = response.content.select { |b| b.type == :tool_use }
            return finish(texts) if tool_uses.empty?

            # Pass the SDK blocks back unchanged (thinking included); to_h would use Ruby-side key names
            messages << { role: "assistant", content: response.content }
            messages << { role: "user", content: tool_uses.map { |tool_use| run_tool(tool_use) } }
        end

        raise AgentError, "The assistant took too many steps, please try a simpler request"
    end

    def create_message(messages)
        client.messages.create(
            model: ENV.fetch("TRIP_AGENT_MODEL", "claude-sonnet-5-5"),
            max_tokens: MAX_TOKENS,
            thinking: { type: "adaptive" },
            output_config: { effort: :medium },
            system_: [
                { type: "text", text: INSTRUCTIONS, cache_control: { type: "ephemeral" } },
                { type: "text", text: "# Current trip\n\n#{TripContextBuilder.new(@trip, @user).call}" }
            ],
            tools: [ PROPOSE_CHANGES_TOOL ],
            messages: messages,
            # Retry on another model if a safety classifier declines the request
            request_options: {
                extra_headers: { "anthropic-beta" => "server-side-fallback-2026-07-01" },
                extra_body: { fallbacks: "default" }
            }
        )
    end

    def check_stop_reason!(response)
        case response.stop_reason
        when :refusal
            raise AgentError, "The assistant couldn't help with that request"
        when :max_tokens
            raise AgentError, "The assistant's reply was too long, please try a smaller request"
        end
    end

    def finish(texts)
        text = texts.join("\n\n").strip
        text.presence || (@proposed_changes.present? ? "Here are my suggested changes." : "I'm not sure how to help with that.")
    end

    # Earlier turns as plain text; proposals are summarised so the model knows what the group did with them
    def history
        records = @trip.trip_agent_messages.includes(:user, :proposal)
                       .order(created_at: :desc).limit(HISTORY_LIMIT).to_a.reverse

        turns = records.map do |m|
            if m.role == "user"
                { role: "user", content: "#{m.user&.name || 'Someone'}: #{m.content}" }
            else
                { role: "assistant", content: [ m.content, proposal_note(m.proposal) ].compact.join("\n\n") }
            end
        end

        # The API needs alternating roles starting with the user
        turns.drop_while { |t| t[:role] == "assistant" }.chunk_while { |a, b| a[:role] == b[:role] }.map do |group|
            { role: group.first[:role], content: group.map { |t| t[:content] }.join("\n\n") }
        end
    end

    def proposal_note(proposal)
        return unless proposal
        summaries = proposal.changes_list.map { |c| c["summary"] }.join("; ")
        "[Proposed #{proposal.changes_list.size} changes (#{summaries}), status: #{proposal.status}]"
    end

    def run_tool(tool_use)
        result = { type: "tool_result", tool_use_id: tool_use.id }
        unless tool_use.name == "propose_changes"
            return result.merge(content: "Unknown tool #{tool_use.name}", is_error: true)
        end

        input = tool_use.input.to_h.deep_stringify_keys
        changes, errors = build_changes(Array(input["changes"]))
        if errors.any?
            return result.merge(content: "Proposal rejected, fix these and call propose_changes again:\n#{errors.join("\n")}", is_error: true)
        end

        @proposed_changes = changes
        result.merge(content: "Proposal saved with #{changes.size} changes for the group to review. Now reply to the user.")
    end

    def build_changes(raw_changes)
        days = @trip.itinerary_days.index_by(&:day_number)
        items = ItineraryItem.joins(:itinerary_day).where(itinerary_days: { trip_id: @trip.id }).index_by { |i| i.id.to_s }
        errors = []
        errors << "changes is empty" if raw_changes.empty?

        changes = raw_changes.each_with_index.filter_map do |raw, index|
            item = items[raw["item_id"].to_s]
            error = validation_error(raw, days, item)
            if error
                errors << "change #{index + 1} (#{raw['action']}): #{error}"
                next
            end

            normalize_change(raw, index, item)
        end

        [ changes, errors ]
    end

    def validation_error(raw, days, item)
        if !ACTIONS.include?(raw["action"])
            "unknown action"
        elsif !days.key?(raw["day_number"].to_i)
            "day_number #{raw['day_number']} doesn't exist (trip has days 1-#{days.keys.max})"
        elsif ITEM_ACTIONS.include?(raw["action"]) && item.nil?
            "item_id #{raw['item_id'].inspect} is not an item in this trip"
        elsif raw["action"] == "add" && raw["title"].blank?
            "add needs a title"
        elsif raw["scheduled_time"].present? && raw["scheduled_time"] !~ /\A\d{2}:\d{2}(:\d{2})?\z/
            "scheduled_time must be HH:MM:SS"
        end
    end

    def normalize_change(raw, index, item)
        change = {
            "id" => "c#{index + 1}",
            "action" => raw["action"],
            "day_number" => raw["day_number"].to_i,
            "item_id" => item&.id&.to_s,
            "summary" => raw["summary"].to_s,
            "before" => item && snapshot(item),
            "after" => after_snapshot(raw, item)
        }
        # Fingerprint used at apply time to detect the item changing since the proposal was made
        change["item_updated_at"] = item.updated_at.iso8601(6) if item
        change["idea_card_id"] = raw["idea_card_id"].presence if raw["action"] == "add"
        change
    end

    def snapshot(item)
        {
            "title" => item.title,
            "notes" => item.notes,
            "scheduled_time" => item.scheduled_time&.strftime("%H:%M:%S"),
            "time_of_day" => item.time_of_day,
            "address" => item.address,
            "day_number" => item.itinerary_day.day_number
        }
    end

    def after_snapshot(raw, item)
        case raw["action"]
        when "remove"
            nil
        when "update_day"
            raw.slice("city", "accommodation_name", "accommodation_address").compact
        else
            base = item ? snapshot(item) : {}
            fields = raw.slice("title", "notes", "address").compact
            time = normalize_time(raw["scheduled_time"])
            fields.merge!("scheduled_time" => time, "time_of_day" => time_of_day_for(time)) if time
            base.merge(fields).merge("day_number" => raw["day_number"].to_i)
        end
    end

    def normalize_time(value)
        return if value.blank?
        value.length == 5 ? "#{value}:00" : value
    end

    def time_of_day_for(time)
        hour = time.to_i
        if hour < 12 then "morning" elsif hour < 18 then "afternoon" else "evening" end
    end
end
