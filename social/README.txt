Six Degrees of Separation (Puzzle node problem #14)


The following snippet in an .rb file should exercise the object as I did in my tests

require File.dirname(__FILE__) + '/social_graph.rb'

file = File.read('complex_input.txt')
@communication = SocialGraph::Communication.new(file)
@communication.analyze(6)
@communication.output("complex_output.txt")

I solved this program first, but struggled a great deal refactoring idiomatically and representing an algorithm for distances in a clean way, initially using Floyd's shortest path algorithm in a very procedural implementation, and refactoring first to a be more object oriented and idiomatic, and then to using a recursive distance function on the user class.  I also struggled with whether and how to use "edge" or connection class objects for representing first degree connections and also higher weight derived connections.  Eventually I left only first degree connections as edges, and stored user names from higher levels in a hash keyed on the distance, which simplified output but feels a little bit awkward as well.

(I'm including my initial procedural version for reference, though I have no idea if you want to consider such "uncleaned up" code, but since it's so radically different and was much much easier to implement and debug, I'm curious if it's really as bad as I judged it compared to some of the complexity introduced by the OO approach.  The version included appears not to alphabetized output, a revision I apparently lost, but otherwise passed validation with that fix, for reference.)