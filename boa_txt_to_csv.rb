#!/usr/bin/env ruby

require 'csv'

if ARGV[0].nil?
  puts "Usage: #{__FILE__} path/to/input.txt > output.csv"
  exit 1
end

DATE_MATCH = /[0-9]{2}\/[0-9]{2}/
STARTS_WITH_DATE_MATCH = /^ +?#{DATE_MATCH}/

def match_indexes(string, regex)
  matches = string.match(regex)

  (1...matches.length).map do |index|
    [matches.begin(index), matches.end(index) - 1]
  end
end

def parse(row1, row2 = nil)
  return if !row1.match(/^ +#{DATE_MATCH} +#{DATE_MATCH} +/)

  description_start, _ =
    *(match_indexes(row1, /^ +#{DATE_MATCH} +#{DATE_MATCH} +([A-Z0-9#\- _]+)/ )[0])
  description_end = description_start + 22

  city_start = description_start + 23
  city_end = city_start + 12

  tx_date, post_date = *row1.match(/^ +(#{DATE_MATCH}) +(#{DATE_MATCH}) +/).captures
  description1 = row1[ description_start...description_end ].strip
  city         = row1[ city_start...city_end ].strip

  return if tx_date.empty?
  return if description1.match(/Interest Charged on/)

  state, ref_no, acct_no, amount =
    *row1.match(/([A-Z]{2}) +([0-9]+) +([0-9]+) +([0-9.,]+)$/).captures

  if row2 && match = row2.match(/^ {33}([A-Z0-9#\-]+?)$/)
    description2 = match.captures.first
  end

  [tx_date, post_date, description1, description2, city, state, ref_no, acct_no, amount]
end

CSV {|out| out << ["TX Date", "Post Date", "Description", "Description 2",
                   "City", "State", "Reference #", "Account #", "Amount"]}

file = File.read(ARGV[0])
file.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '')

file.gsub(/[\r\n]+/, "\n").lines.inject("") do |previous_row, current_row|
  next current_row if previous_row.empty?

  if previous_row.match(STARTS_WITH_DATE_MATCH)
    if current_row.match(STARTS_WITH_DATE_MATCH) # two csv rows of data
      CSV {|out| row = parse(previous_row); out << row if row}
      CSV {|out| row = parse(current_row); out << row if row}
    else # one row of data taking up two physical rows
      CSV {|out| row = parse(previous_row, current_row); out << row if row}
    end
  end

  ""
end