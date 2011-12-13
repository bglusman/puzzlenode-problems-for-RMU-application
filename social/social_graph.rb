module SocialGraph
  require 'set'

  class Communication
    attr_accessor :network
    def initialize(comm_file)
       populate_network(comm_file)
    end

    def populate_network(file)
      self.network = Network.new
      tweet = %r{(\S+)\:(.*)}

      file.split("\n").each do |line|
        line =~ tweet
        network.add_user $1
        network.add_message $1, $2
      end
    end

    def analyze(depth_level)
      network.create_connections
      network.analyze(depth_level)
    end

    def output(outfile)
      raise "Please analyze data to a configurable level of depth before output" unless network.analyzed?
      output = network.relationships
      File.open(outfile, 'w') do|f|
        f.write(output[0..-2]) #removing extra newline
      end
    end
  end

  class Network
    attr_reader :max_depth, :users
    def initialize
      @users, @analyzed, @max_depth, @connections = [], false, 1, []
    end

    def add_user(user)
      users << User.new(user, self) unless get(user)
    end

    def add_message(user, message)
      sender = get(user)
      sender.add_message(message)
    end

    def get(user)
      users.select{|u|u.name == user}.first
    end

    def create_connections
      users.each do |user|
        user.mentions.each do |mention|
          other = get(mention)
          if other && other.unconnected_friends_with?(user)
            connection = connect(user, other)
            user.connections << connection if connection
            other.connections << connection if connection
          end
        end
      end
    end


    def connect(user1, user2)
      debugger if user2.friends.include?(user1)
      Connection.new(user1, user2) unless user1 == user2 if user1.unconnected_friends_with?(user2)
    end

    def analyze(depth)
      users.each do |user|
        1.upto(depth) do |level|
          users.each do |other_user|
            next if user == other_user
            if user.distance_to(other_user.name) == level &&  !user.connected_to(other_user.name)
              user.degrees[level] ||= []
              other_user.degrees[level] ||=[]
              user.degrees[level] << other_user.name unless user.degrees[level].include? other_user.name
              other_user.degrees[level] << user.name unless other_user.degrees[level].include? other_user.name
            end
          end
        end
      end

      @analyzed = true
    end

    def relationships
      users.sort! { |a, b| a.name <=> b.name }
      users.reduce("") {|output, user| output << user.output}
    end

    def analyzed?
      @analyzed
    end
  end


  class User
    attr_accessor :name, :network, :messages, :connections, :mentions, :degrees
    def initialize(name, network)
      @name, @network, @messages, @connections, @mentions, @degrees = name, network, [], [], Set.new, {}
      @calls = []
    end

    def add_message(text)
      messages << message = Message.new(text)
      self.mentions += message.mentions
    end

    def distance_to(user_name)
      recurse_to(user_name, rand) unless user_name==self.name #random number per starting request
    end

    def connected_to(user)
      degrees.reduce(false) do |accum, (level, names)|  #level is unused, but key to hash
        accum || names.include?(user)
      end
    end

    def friends
      connections.map {|c| edge_user(c)}
    end

    def friends_names
      connections.map {|c| edge_user(c).name}
    end

    INF = 1.0/0.0
    def recurse_to(user_name, id)
      if friends_names.include?(user_name)
        return 1
      elsif @calls.include?(id)
        return nil
      else
        @calls << id
        distances = friends.map do |friend|
          if dist= friend.recurse_to(user_name, id)
            (1 + dist)
          else
            INF
          end
        end
        distances.compact.min
      end
    end

    def unconnected_friends_with?(user)
      mentions.include?(user.name) && user.mentions.include?(self.name) &&
      !friends.include?(user) && !user.friends.include?(self)
    end


    def output
      details = "#{name}\n"
      degrees.each do |level, names|
        names.sort!
      end
      degrees.keys.sort.each do |key|
        degrees[key].each{|name| details << @flag="#{name}, "}
        details = "#{details[0..-3]}\n" if @flag
      end

      details + "\n"
    end

    def edge_user(edge)
      edge.other_user(self)
    end

    def remove_edge(user)  #this is currently unused, but might be a useful in refactor
      connections.each do|level, edges|
        edges.reject! {|edge| edge.other_user(self)}
      end
    end
  end

  class Message
    attr_reader :text
    def initialize(text)
      @text = text
    end

    def mentions
      at_user = %r{.*?@(\w+)}
      users = []
      text.scan(at_user).each {|mention| users << mention.first }

      users
    end
  end

  class Connection
    attr_reader :user1, :user2, :distance

    def initialize(user_a, user_b)
      raise  'Nil user' if user_a.nil? || user_b.nil?
      raise 'Add the users to a network before adding connections' if (user_a.network.nil? || user_b.network.nil?)
      raise "Can't add a connection between users on different networks" if (user_a.network != user_b.network)
      raise "Can't connect user to themself" if user_a == user_b
      #these are all invalid conditions, but is raising for invalid right?  should I do consistently everywhere, or is that rigid?

      @user1, @user2 = user_a, user_b
    end

    # expects one of the two connecting users, returns the other
    def other_user(user)
      return user2 if (user == user1)
      return user1 if (user == user2)

      nil
    end
  end
end