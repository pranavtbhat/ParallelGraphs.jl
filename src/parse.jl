################################################# FILE DESCRIPTION #########################################################

# ParallelGraphs will eventually support several file formats for reading and writing graphs.
# However currently, only a modified version of the Trivial Graph Format is supported. The TGF
# is described below:
# 
# The input file should contain data in the following format:
# <num_vertices> <num_edges>
# <vertex_id> <vertex_prop_1> <val_1> <vertex_prop_2> <val_2> ...
# .
# .
# .
# <from_vertex_id> <to_vertex_id> <edge_property_1> <val_1> <edge_property_2> <val_2> ...
# .
# .
# .
# EOF

################################################# IMPORT/EXPORT ############################################################
export parsegraph


################################################# PARSEGRAPH ###############################################################
""" Parse a text file in a given format """
function parsegraph(filename::AbstractString, format::Symbol, graph_type=SparseGraph)
   (format == :TGF) && return parsegraph_tgf(filename, graph_type)
   error("Invalid graph format")
end

################################################# TRIVIAL GRAPH FORMAT #####################################################

""" Parse a text file in the trivial graph format """
function parsegraph_tgf(filename::AbstractString, graph_type)
   @inline function parse_vertex(g, args)
      v = parse(Int, args[1])
      for i in eachindex(args)[2:2:end-1]
         propname = join(args[i])
         val = join(args[i+1])
         val = isnumber(val) ? parse(Int, val) : val
         setvprop!(g, v, val, propname)
      end
   end

   @inline function parse_edge(g, args)
      v1, v2 = map(x->parse(Int, x), args[1:2])
      addedge!(g, v1, v2)
      for i in eachindex(args)[3:2:end-1]
         propname = join(args[i])
         val = join(args[i+1])
         val = isnumber(val) ? parse(Int, val) : val
         seteprop!(g, v1, v2, val, propname) 
      end
   end

   file = open(filename)
   nv, ne = map(x->parse(Int, x), split(readline(file), " "))
   g = graph_type(nv)

   while !eof(file)
      line = strip(readline(file), '\n')
      args = split(line, " ")
      (length(args) == 0 || length(line) == 0) && continue

      if length(args) % 2 == 1
         parse_vertex(g, args)
      elseif length(args) % 2 == 0
         parse_edge(g, args)
      end
   end

   return g
end