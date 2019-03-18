MAX_SHANTEN = 8

#------------------------------------------------------------------------------
# * Helper Functions
#------------------------------------------------------------------------------

def suuhai?(tile)
  return tile < 27
end

def yaochuuhai?(tile)
  return true if tile > 26
  return [0, 8].include?(tile % 9)
end

def parse_hand(tenhou_hand)
  return tenhou_hand.split(",").map { |s| s.to_i / 4 }.sort
end

#------------------------------------------------------------------------------
# * Shanten Calculation
#------------------------------------------------------------------------------

def chiitoi_shanten(hand)
  return MAX_SHANTEN if not [13, 14].include?(hand.size)
  shanten = 6

  curr_tile = -1
  curr_tile_count = 0

  hand.each { |tile|
    curr_tile_count += 1
    if curr_tile != tile
      shanten -= 1 if curr_tile_count > 1
      curr_tile = tile
      curr_tile_count = 0
    end
  }

  return shanten
end

def kokushi_shanten(hand)
  return MAX_SHANTEN if not [13, 14].include?(hand.size)

  shanten = 13
  last_yaochuuhai = -1
  pair = 0

  hand.each { |tile|
    next if not yaochuuhai?(tile)

    if last_yaochuuhai == tile
      pair = 1
      next
    end

    last_yaochuuhai = tile
    shanten -= 1
  }

  return shanten - pair
end

def mentsu_shanten(hand, shanten = 8, mentsu = 4, has_jantou = false)
  return shanten if mentsu == 0 and has_jantou
  return shanten if hand.size <= 1

  candidate_shanten = []

  tile = hand[0]
  if mentsu > 0 and hand.size > 2 and tile == hand[1] and tile == hand[2]
    candidate_shanten.push(
      mentsu_shanten(hand[3..-1], shanten - 2, mentsu - 1, has_jantou),
    )
  end

  if mentsu > 0 and hand.size > 2 and suuhai?(tile) and tile % 9 < 7
    one_adj_index = hand.index(tile + 1)
    two_adj_index = hand.index(tile + 2)

    if one_adj_index and two_adj_index
      dup_hand = hand.dup

      dup_hand.delete_at(two_adj_index)
      dup_hand.delete_at(one_adj_index)
      dup_hand.delete_at(0)

      candidate_shanten.push(
        mentsu_shanten(dup_hand, shanten - 2, mentsu - 1, has_jantou),
      )
    end
  end

  if tile == hand[1]
    if has_jantou and mentsu > 0
      candidate_shanten.push(
        mentsu_shanten(hand[2..-1], shanten - 1, mentsu - 1, has_jantou),
      )
    else
      candidate_shanten.push(
        mentsu_shanten(hand[2..-1], shanten - 1, mentsu, true),
      )
    end
  end

  if mentsu > 0 and suuhai?(tile) and tile % 9 < 8
    taatsu_index = hand.index(tile + 1)
    taatsu_index = hand.index(tile + 2) if not taatsu_index and tile % 9 < 7

    if taatsu_index
      dup_hand = hand.dup

      dup_hand.delete_at(taatsu_index)
      dup_hand.delete_at(0)

      candidate_shanten.push(
        mentsu_shanten(dup_hand, shanten - 1, mentsu - 1, has_jantou),
      )
    end
  end

  candidate_shanten.push(
    mentsu_shanten(hand[1..-1], shanten, mentsu, has_jantou),
  )

  return candidate_shanten.min
end

def shanten(hand)
  return [chiitoi_shanten(hand), kokushi_shanten(hand), mentsu_shanten(hand)].min
end