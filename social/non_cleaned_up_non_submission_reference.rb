require 'ruby-debug'
module Graph
  class World
    TWEET = %r{(\S+)\:(.*)}
 

    attr_reader :users
    def initialize(file)
      @file = file
      @lines = file.split("\n")
      @users = {}
      @lines.each do |line|
        line =~ TWEET
        @users[$1] ||= Graph::Node.new $1
        @users[$1].data << $2
      end
      build_graph
    end

    def count
      users.count
    end

    NAN = 0.0/0.0
    INF = 1.0/0.0

    def build_graph
      @users.each {|name, node| @users.each {|user, node2| node.distances[user] = [INF, node2]}}
      @users.each do|me, my_node|
        my_node.distances.each do |user, pair|
          node2 = pair.last
          if my_node.sent.member?(user) && node2.sent.member?(me)
            pair[0] = 1
          end
        end
      end

      @users.each do|me, my_node|
        my_node.distances.each do |user, pair|
          @users.each do |connection, pair2|
            node2 = pair.last
            combined = my_node.distance_to(connection) + @users[connection].distance_to(user)
            if  combined < my_node.distance_to(user)
              pair[0] = combined
              node2.distances[me][0] = combined
            end
          end
        end
      end
    end

    def graph(user1, user2)
      @users[user1].distance_to(user2)
    end

    def output(file)
      File.open(file, 'w') {|f| @users.each_with_index do |(user, node), index|
        f.write(output_user(user) + "\n") unless @users.size == index+1
        f.write(output_user(user)) if @users.size == index+1
      end}
    end

    def output_user(user)
      output = "#{user}\n"
      1.upto(5) do |current_distance|
        users = false
        @users[user].distances.each do |user2, (distance, node)|
          users=output << "#{user2}, " if distance == current_distance && user != user2
        end
        output = "#{output[0..-3]}\n" if users
      end


      output
    end

  end

  class Node
    attr_accessor :data, :distances
    def initialize(user)
      @user = user
      @data = []
      @distances = {}
    end
   MENTION = %r{.*?@(\w+)}
    def sent
      @sent ||= begin
        build = Set.new
        data.each do |message|
          message.scan(MENTION).each do |mention|
            build << mention.first
          end
        end

      build
      end
    end

    def distance_to(other)
      distances[other].first
    end

  end

end