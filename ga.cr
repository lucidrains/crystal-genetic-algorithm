class Gene
  getter :code
  getter :cost
  setter :cost

  def initialize(
    code = "",
    cost = 1_000_000
  )
    @code = code
    @cost = cost
  end

  def mutate!
    random = Random.new
    rand_index = random.rand(@code.size)
    mutation = random.rand(2) == 0 ? 1 : -1

    code_chars = @code.chars
    char = code_chars[rand_index]
    code_chars[rand_index] = (char.ord + mutation).clamp(0, 255).chr
    @code = code_chars.join
  end

  def init_random_gene!(length)
    random = Random.new
    length.times { @code += random.rand(255).chr }
  end
end

class Population
  getter :pool
  getter :solved

  def initialize(
    size : Int32,
    goal : String,
    keep_fittest_frac = 0.25,
    mutate_prob = 0.5
  )
    @pool = [] of Gene

    @size = size
    @goal = goal
    @goal_length = goal.size

    @num_keep_fittest = (keep_fittest_frac * size).to_i
    @mutate_prob = mutate_prob
    @generation = 0
    @solved = false

    init_genes!
  end

  def init_genes!
    @size.times do
      gene = Gene.new

      gene.init_random_gene!(@goal_length)
      self.calc_cost!(gene)

      @pool << gene
    end

    self.sort_by_cost!
  end

  def calc_cost!(gene)
    raise "genetic code and goal must be same length" if @goal.size != gene.code.size

    cost = 0
    code = gene.code

    @goal_length.times do |i|
      cost += (@goal[i].ord - code[i].ord) ** 2
    end

    gene.cost = cost
  end

  def sort_by_cost!
    @pool.sort! { |x, y| x.cost <=> y.cost }
  end

  def keep_fittest!
    @pool = @pool[0...@num_keep_fittest]
  end

  def mutate_pool!
    random = Random.new
    @pool.each do |gene|
      gene.mutate! if random.rand < @mutate_prob
    end
  end

  def breed!
    (@size - @pool.size).times do
      rand_parent_indices = (0...@pool.size).to_a.shuffle[0...2]

      gene1_index, gene2_index = rand_parent_indices
      gene1, gene2 = @pool[gene1_index], @pool[gene2_index]

      code_mid_index = @goal_length // 2
      crossover_code = gene1.code[0...code_mid_index] + gene2.code[code_mid_index...]

      child = Gene.new(crossover_code)
      self.calc_cost!(child)

      @pool << child
    end
  end

  def next_generation!
    return if @solved

    self.keep_fittest!

    self.breed!

    self.mutate_pool!

    @pool.each do |gene|
      self.calc_cost!(gene)
    end

    self.sort_by_cost!

    @solved = @pool[0].cost == 0

    @generation += 1

    self.print
  end

  def print
    puts "\33c\e[3J"
    puts "Generation: #{@generation}\n\n"

    @pool.each_with_index do |gene, i|
      puts "#{i + 1}: #{gene.code} (#{gene.cost})"
    end
  end
end

population = Population.new(
  size = 40,
  goal = "Attention is all you need",
  keep_fittest_frac = 0.25
)

until population.solved
  population.next_generation!
end
