require 'dota'
require 'pry'

players = {
  94999189 => 'Matthias',
  11843866 => 'Valentin'
}

Dota.configure do |config|
  config.api_key = ENV.fetch('STEAM_API_KEY')
end

def matches_won(matches, player_id)
  won = matches.inject(0) do |sum, match|
    radiant_ids = match.radiant.players.map(&:id)
    was_radiant = radiant_ids.include? player_id
    radiant_won = match.winner == :radiant
    sum + (was_radiant == radiant_won ? 1 : 0)
  end

  won
end

SCHEDULER.every '1h', first_in: 0 do
  api = Dota.api

  a_week_ago = (Date.today - 7).to_time
  two_weeks_ago = (Date.today - 14).to_time

  players.each do |player_id, name|
    matches = api.matches(player_id: player_id)
    matches_last_week = matches.select do |match|
      match.starts_at > a_week_ago
    end

    matches_before_last_week = matches.select do |match|
      match.starts_at < a_week_ago &&  match.starts_at > two_weeks_ago
    end

    results = {
      current: matches_won(matches_last_week, player_id),
      last: matches_won(matches_before_last_week, player_id)
    }

    send_event "dota-#{name}", results
  end
end
