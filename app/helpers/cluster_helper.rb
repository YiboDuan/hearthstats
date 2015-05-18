require 'matrix.rb'
class ClusterHelper

  # Differences in linking strategies occur in distance updating
  CLINK = Proc.new do |i,j|
    [i[1],j[1]].max
  end

  ALINK = Proc.new do |i_size,j_size,i,j|
    (i[1]*i_size + j[1]*j_size)/(i_size+j_size)
  end

  def self.cluster(decks, link_strategy)
    case link_strategy
    when 'a'
      link = ALINK
      p "Average Linking"
    when 'c'
      link = CLINK
      p "Complete Linking"
    else
      p "Invalid strategy"
      return
    end
    self.cluster_decks(decks, link)
  end

  def self.cluster_decks(decks, link)
    cluster_tree = Array.new
    n = decks.size
    distances = init(decks)
    _link = link.curry
    # number of merges: used for indexing
    m_count = 0
    # merge clusters until there is one remaining
    while distances.size > 1
      distances = sort_matrix(distances)
      i = distances[0][0]
      j = distances[0][1][0]
      c1,cluster_tree = search_clusters(i, n, cluster_tree)
      c2,cluster_tree = search_clusters(j, n, cluster_tree)
      # use n as an offset for indexing
      c1.kind_of?(Integer) ? (c1_size = 1) : (c1_size = c1[1])
      c2.kind_of?(Integer) ? (c2_size = 1) : (c2_size = c2[1])
      index = n + m_count
      cluster_tree.push([index, c1_size + c2_size, c1, c2])
      link.arity == 4 ? (mod_link = _link[c1_size,c2_size]) : (mod_link = _link)
      distances = update_distances(distances, i, j, index, mod_link)
      m_count += 1
    end
    cluster_tree.compact
  end

  # if index exists as a cluster in the tree, return it
  # and delete the node from the tree. otherwise, return index
  def self.search_clusters(index, offset, cluster_tree)
    node = index
    if index >= offset
      index = index - offset
      node = cluster_tree[index]
      cluster_tree[index] = nil
    end
    return node, cluster_tree
  end

  def self.init(decks)
    pre_merge(gen_matrix(decks))
  end


  def self.update_distances(m, i, j, index, link)
    m = merge_rows(m,i,j,index,link)
    merge_columns(m,i,j,index,link)
  end


  def self.merge_rows(m, i, j, max_index, link)
    i_row = row_slice(m.delete(m.assoc(i)))
    j_row = row_slice(m.delete(m.assoc(j)))
    merge_row = Array.new
    # add the higher distance to the new row
    (0..max_index-1).each do |k|
      next if k == i or k == j
      i_tuple = i_row.assoc(k)
      j_tuple = j_row.assoc(k)
      unless i_tuple.nil? or j_tuple.nil?
        new_tuple = [k, link.call(i_tuple, j_tuple)]
      end
      merge_row.push(new_tuple) unless new_tuple.nil?
    end
    # Sort by distance again, and insert assoc value again
    merge_row = merge_row.sort_by{|x| x[1]}.insert(0,max_index)
    m.push(merge_row)
  end

  def self.merge_columns(m, i, j, index, link)
    # merge columns
    m.each do |row|
      col = row[1..row.size-1].select{|x| x[0] == i || x[0] == j}
      if col.size > 0
        row.delete(col[0])
        row.delete(col[1])
        row.push([index,link.call(col[0],col[1])])
      end
    end
    m
  end

  def self.row_slice(row)
    row[1..row.size-1].sort_by{|x| x[0]}
  end

  def self.gen_matrix(decks)
    n = decks.size
    matrix = Array.new
    (0..n-1).each do |i|
      row = Array.new
      (0..n-1).each do |j|
        if i == j
          row.push([j,0])
        elsif i > j
          if matrix[j][i] == nil
            puts "Tried to reference nil cell... break."
            raise
          end
          row.push([j,matrix[j][i][1]])
        else
          row.push([j,get_distance(decks[i],decks[j])])
        end
      end
      matrix.push(row)
    end
    matrix
  end

  def self.sort_matrix(m)
    m.each do |row|
      i = row.delete_at(0)
      row.sort_by!{|x| x[1]}.insert(0,i)
    end
    m.sort_by!{|x| x[1][1]}
  end

  def self.pre_merge(m)
    m.each_with_index do |row, i|
      row.delete([i,0])
      row.insert(0,i)
    end
    m
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
    print "\n"
    m.each do |row|
      row.each do |j|
        align_print(j)
      end
      print "\n"
    end
  end

  def self.align_print(item)
    print item.to_s
    print " " if item[1] < 10
    print "|"
  end

  def self.print_spaces(n)
    n.times {print " "}
  end
end