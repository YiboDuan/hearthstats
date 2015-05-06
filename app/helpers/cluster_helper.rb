require 'matrix.rb'
class ClusterHelper

  def self.gen_matrix(decks)
    n = decks.size
    matrix = Array.new
    (0..n-1).each do |i|
      row = Array.new
      (0..n-1).each do |j|
        if i == j
          row.push(0)
        elsif i > j
          if matrix[j][i] == nil
            "Tried to reference nil cell... break."
            raise
          end
          row.push(matrix[j][i])
        else
          row.push(get_distance(decks[i],decks[j]))
        end
      end
      matrix.push(row)
    end
    return matrix
  end

  def self.get_distance(a, b)
    a_cards = get_card_id_list(a)
    b_cards = get_card_id_list(b)
    compare(a_cards,b_cards)
  end

  def self.get_card_id_list(deck)
    UniqueDeckCard.where(unique_deck_id: deck.id).map{|x| x.card_id}
  end

  def self.compare(a, b)
    t = Hash.new(0)
    a.each {|i| t[i] += 1}
    b.each {|i| t[i] -= 1}
    count = 0
    t.each {|i| count += i[1].abs}
    count / 2
  end

  def self.print_matrix(m)
    print "  |"
    (0..m.size-1).each do |i|
      align_print(i)
    end
    print "\n"
    m.each_with_index do |row,i|
      align_print(i)
      row.each do |j|
        align_print(j)
      end
      print "\n"
    end
  end

  def self.align_print(item)
    print item.to_s
    print " " if item < 10
    print "|"
  end
end