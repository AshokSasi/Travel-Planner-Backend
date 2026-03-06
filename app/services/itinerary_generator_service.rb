class ItineraryGeneratorService
    def initialize(trip, preferences)
        @trip = trip
        @preferences = preferences
        @num_days = (trip.end_date - trip.start_date).to_i + 1
    end

    def call
        client = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])

        response = client.messages.create(
            model: "claude-haiku-4-5-20251001",
            max_tokens: 8000,
            messages: [{role: "user", content: prompt}]
        )

        text = response.content.first.text.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '').strip
        result = JSON.parse(text)
        create_itinerary(result)
    end

    private

    def prompt
        <<~PROMPT
        Generate a detailed travel itinerary for this trip:
        Destination: #{@trip.location}
        Start Date: #{@trip.start_date}
        End Date: #{@trip.end_date}
        Number of Days: #{@num_days}
        Budget: #{@preferences[:budget]}
        Travel style: #{@preferences[:travel_style]}
        Group type: #{@preferences[:group_type]}
        Interests: #{format_interests}
        Return ONLY a valid JSON object, no other text, no markdown, no backticks:
      {
        "days": [
          {
            "day_number": 1,
            "date": "YYYY-MM-DD",
            "city": "City name",
            "accommodation_name": "Hotel name",
            "accommodation_address": "Full address",
            "items": [
              {
                "title": "Activity name",
                "notes": "Brief description and tips",
                "scheduled_time": "HH:MM:SS",
                "time_of_day": "morning",
                "order_index": 0
              }
            ]
          }
        ]
      }

      Rules:
      - time_of_day must be one of: morning, afternoon, evening
      - scheduled_time must be in HH:MM:SS format
      - Generate 3-5 items per day
      - Be specific with real place names and addresses
      - If interests include Food & Nightlife, include at least one restaurant or bar per day
      - If interests include Nature & Outdoors, avoid scheduling indoor activities in the morning
      - If no interests specified, generate a balanced mix of everything
    PROMPT
    end

    def format_interests
        return "Balanced mix of everything" if @preferences[:interests].blank?
        @preferences[:interests].join(", ")
    end

  CARD_COLUMN_WIDTH = 320
  CARD_ROW_HEIGHT = 180

  def create_itinerary(result)
    created_days = []

    result["days"].each_with_index do |day_data, day_index|
      day = @trip.itinerary_days.find_by(day_number: day_data["day_number"])
      next unless day

      day.update!(
        city: day_data["city"],
        accomodation_name: day_data["accommodation_name"],
        accomodation_address: day_data["accommodation_address"]
      )

      day.itinerary_items.destroy_all

      day_data["items"].each_with_index do |item, item_index|
        idea_card = @trip.idea_cards.create!(
          title: item["title"],
          content: item["notes"],
          x: day_index * CARD_COLUMN_WIDTH,
          y: item_index * CARD_ROW_HEIGHT
        )
        day.itinerary_items.create!(
          title: item["title"],
          notes: item["notes"],
          scheduled_time: item["scheduled_time"],
          time_of_day: item["time_of_day"],
          order_index: item["order_index"],
          idea_card: idea_card
        )
      end

      created_days << day
    end

    created_days
  end

end