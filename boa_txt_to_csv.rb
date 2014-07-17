#!/usr/bin/env ruby

require 'csv'
require 'pry'

if ARGV[0].nil?
  puts "Usage: #{__FILE__} path/to/input.txt > output.csv"
  exit 1
end

DATE_MATCH = /[0-9]{2}\/[0-9]{2}/
DESCRIPTION_MATCH = /[[:print:]]{22}/
DESCRIPTION2_MATCH = /[[:print:]]{13}/
LATE_FEE_DESCRIPTION_MATCH = /[[:print:]]{50}/
AMOUNT_MATCH = /[0-9.,]+/
STARTS_WITH_DATE_MATCH = /^ +?#{DATE_MATCH}/

PLACES = ['GIG HARBOR', 'PORT ORCHARD', 'UNIVERSITY P', 'NEW YORK']

def parse(row)
  return if row.empty?

  amount, credit = *row.match(/([\d,]{1,}\.\d{2})(CR)?$/).captures

  city ||= PLACES.find {|p| row.include?(p)}
  comma_match = row.match(/ ([^ ]+),([^ ]+) #{amount}/)
  if comma_match
    city2, state = *comma_match.captures
  end
  city ||= city2
  begin
    city = row.match(/([^ ]+?) #{amount}/).captures.first if !city
  rescue
    binding.pry
    raise
  end

  amount = "-#{amount}" if credit

  date = row.match(/^([^ ]+) /).captures.first

  begin
    description = row.match(/^[^ ]+? (.+?) #{city}/).captures.first
  rescue
    binding.pry
    raise
  end

  [date, description, city, state, amount].map {|e| e.strip if e}
end

CSV {|out| out << ["Date", "Description", "City", "State", "Amount"]}

file = File.read(ARGV[0])
file.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '')

file.gsub(/[\r\n]+/, "\n").lines do |row|
  next if row.empty?

  CSV {|out| out << parse(row)}
end
