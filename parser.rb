require 'set';

WordWithSubs = Struct.new :word_to_match, :potential_match, :substitutions

module Dictionary
  def self.dictionary
    @dictionary ||= File.read('/usr/share/dict/words').lines.map{|l|l.strip.downcase}.uniq
  end

  def self.words_by_count
    @words_by_count ||= dictionary.reduce({}){|h, w| i = w.length; h[i] ||= Set.new; h[i] << w; h}
  end
end

Matcher = Struct.new :word_to_match, :substitutions do
  def matching_words
    potential_words = Dictionary.words_by_count[word_to_match.length]
    matches = []
    potential_words.each do |p_m|
      h = substitutions.dup
      idx = -1
      non_matching_char = p_m.chars.detect do |c|
        idx += 1
        w_c = word_to_match[idx]
        if h[c].nil? && !h.values.include?(w_c)
          h[c] = w_c
          false
        elsif h[c] != w_c
          true
        else
          false
        end
      end

      matches << WordWithSubs.new( word_to_match, p_m, h) \
        if non_matching_char.nil?
    end
    matches
  end
end

class WordChain
  attr_reader :head, :substitutions
  def initialize(head = [], substitutions = {})
    @head = head
    @substitutions = substitutions
  end

  def append(word)
    Matcher.new(word, @substitutions).matching_words.map do |matched_word|
      a = head.dup << matched_word
      WordChain.new(a, matched_word.substitutions)
    end
  end

  def to_s
    Array(head).map{|w| w.potential_match }.join(" ")
  end
end

class Parser
  attr_reader :words
  def initialize(words)
    @words = Array(words).join(" ").downcase.split(/\s+/)
  end

  def run
    words_to_match = words.dup
    substitutions = { "'" => "'" }
    chains = [ WordChain.new ]
    until words_to_match.empty?
      next_word = words_to_match.shift
      puts "Adding #{next_word} to #{chains.length} chains"
      chains = chains.map{|cc| cc.append(next_word)}.flatten
    end
    puts "Have potential options of: #{chains.map(&:to_s).join("\n") }"
  end
end

if __FILE__ == $0
  Parser.new(ARGV).run
end