class ItineraryQuestionsService
    MAX_QUESTIONS = 4

    QUESTIONS_TOOL = {
        name: "ask_questions",
        description: "Ask the traveller short follow-up questions before their itinerary is generated.",
        input_schema: {
            type: "object",
            properties: {
                questions: {
                    type: "array",
                    maxItems: MAX_QUESTIONS,
                    items: {
                        type: "object",
                        properties: {
                            id: { type: "string", description: "Short snake_case id, e.g. regions, pace, must_do" },
                            text: { type: "string" },
                            type: { type: "string", enum: [ "single_select", "multi_select", "text" ] },
                            options: { type: "array", items: { type: "string" } }
                        },
                        required: [ "id", "text", "type" ]
                    }
                }
            },
            required: [ "questions" ]
        }
    }.freeze

    def initialize(trip, preferences)
        @trip = trip
        @preferences = preferences
    end

    def call
        client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

        response = client.messages.create(
            model: "claude-haiku-4-5-20251001",
            max_tokens: 1500,
            tools: [ QUESTIONS_TOOL ],
            tool_choice: { type: "tool", name: QUESTIONS_TOOL[:name] },
            messages: [ { role: "user", content: prompt } ]
        )

        tool_use = response.content.find { |block| block.type == :tool_use }
        input = JSON.parse(tool_use.input.to_json)
        input["questions"].first(MAX_QUESTIONS)
    end

    private

    def prompt
        <<~PROMPT
        A group is about to have a travel itinerary generated for them. Ask a few short follow-up questions
        that would make the itinerary feel personal to them.

        Trip:
        Destination: #{@trip.location}
        Dates: #{@trip.start_date} to #{@trip.end_date} (#{num_days} days)
        Group size: #{@trip.trip_members.count}

        Already answered:
        Budget: #{@preferences[:budget].presence || "not given"}
        Travel style: #{@preferences[:travel_style].presence || "not given"}
        Group type: #{@preferences[:group_type].presence || "not given"}
        Interests: #{@preferences[:interests].presence&.join(", ") || "not given"}
        Pace: #{@preferences[:pace].presence || "not given"}
        Regions: #{@preferences[:regions].presence&.join(", ") || "not given"}
        Notes: #{@preferences[:notes].presence || "none"}

        Ideas the group has already saved: #{idea_titles}

        Rules:
        - Ask at most #{MAX_QUESTIONS} questions, fewer if that's enough. Only ask what would actually change the plan.
        - If the destination is a whole country and no regions were given, the first question must have id "regions",
          type "multi_select", asking which parts of the country they want to explore, with 4-8 specific regions as options.
        - Never ask about anything already answered above.
        - Options must be specific to this destination and season (e.g. named sights, neighbourhoods, activities), not generic.
        - single_select and multi_select questions must include options. text questions must not.
        - Keep question text under 80 characters.
        PROMPT
    end

    def num_days
        (@trip.end_date - @trip.start_date).to_i + 1
    end

    def idea_titles
        titles = @trip.idea_cards.left_joins(:idea_upvotes).group(:id)
                      .order(Arel.sql("COUNT(idea_upvotes.id) DESC")).limit(30).pluck(:title).compact
        titles.any? ? titles.join("; ") : "none"
    end
end
