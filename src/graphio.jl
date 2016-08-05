################################################# FILE DESCRIPTION #########################################################

# ParallelGraphs will eventually support several file formats for reading and writing graphs.
# However currently, only a GraphCSV supported. The format is described below
#
# The input file should contain data in the following format:
# <num_vertices>,<num_edges>,<label_type>(1)
# <vprop1>,<vprop2>,<vprop3>... (2)
# <vproptype1>,<vproptype2>,<vproptype3>... (3)
# <eprop1>,<eprop2>,<eprop3>... (4)
# <eproptype1>,<eproptype2>,<eproptype3>... (5)
# <vertex_label>,<val_1>,<val_2>,<val_3> ... (6)
# .
# .
# .
# <vertex_label>,<val_1>,<val_2>,<val_3> ... (Nv + 5)
# <from_vertex_label>,<to_vertex_label>,<val_1>,<val_2> ... (Nv + 6)
# .
# .
# .
# <from_vertex_label>,<to_vertex_label>,<val_1>,<val_2> ... (Nv + Ne + 5)
# EOF

################################################# IMPORT/EXPORT ############################################################
export
# Read Graphs
loadgraph,
# Write Graphs
storegraph

################################################# HELPERS ##################################################################

parseprops(x::SubString) = Symbol(x)
parseprops(props::Vector) = map(parseprops, props)
parseprops(x) = error("Invalid property name $x")

parsetypes(x::SubString) = eval(parse(x))
parsetypes(props::Vector) = map(parsetypes, props)
parsetypes(x) = error("Invalid Property type $x")

function printif(cond, s::String)
   if cond
      println(s)
   end
end
################################################# READ GRAPHS ##############################################################

function loadheader(io::IO)
   header_line = split(rstrip(readline(io)), ',')
   vprops_line = split(rstrip(readline(io)), ',')
   vtypes_line = split(rstrip(readline(io)), ',')
   eprops_line = split(rstrip(readline(io)), ',')
   etype_line = split(rstrip(readline(io)), ',')

   Nv = parse(header_line[1])
   Ne = parse(header_line[2])
   ltype = eval(parse(header_line[3]))

   vprops = parseprops(vprops_line)
   vtypes = parsetypes(vtypes_line)

   eprops = parseprops(eprops_line)
   etypes = parsetypes(etype_line)

   return(Nv, Ne, ltype, vprops, vtypes, eprops, etypes)
end


function loadgraph(io::IO, graph_type=SparseGraph, verbose=false)
   printif(verbose, "Fetching Graph Header")
   @show Nv, Ne, ltype, vprops, vtypes, eprops, etypes = loadheader(io)

   # Prepend label type to vtypes
   vtypes = vcat(ltype, vtypes)

   # Prepend two integer columns to etypes
   etypes = vcat(Int, Int, etypes)

   printif(verbose, "Fetching Vertex Data")
   @show vdata = CSV.read(io; header=false, datarow=6, rows=Nv, types=vtypes)

   # Strip first column into labels
   printif(verbose, "Fetching Vertex Labels")
   @show ls = vdata[1]

   # Process Vertex DataFrame
   delete!(vdata, 1)
   names!(vdata, vprops)


   printif(verbose, "Fetching Edge Data")
   @show edata = CSV.read(io; header=false, datarow=(Nv+5), rows=Ne, types=etypes)

   # Strip edge columns
   us = edata[1]
   vs = edata[2]
   @show es = EdgeIter(Ne, us, vs)

   # Process Edge DataFrame
   delete!(edata, [1,2])
   names!(edata, eprops)

   printif(verbose, "Constructing Graph")
   Graph(Nv, Ne, SparseMatrixCSC(Nv, eit, 1:Ne), vdata, edata, LabelMap(ls))
end

""" Parse a text file GraphCSV format"""
function loadgraph(filename::String, graph_type=SparseGraph; verbose=false)
   file = open(filename)
   g = loadgraph(file, graph_type, verbose)
   close(file)
   g
end
################################################# WRITE GRAPHS ##############################################################

""" Write a graph to file """
function storegraph(g::Graph, io::IO)
   Nv,Ne = size(g)
   Ltype = eltype(lmap(g))

   Vprops = listvprops(g)
   Vtypes = eltypes(vdata(g))

   Eprops = listeprops(g)
   Etypes = eltypes(edata(g))

   Ls = encode(g, vertices(g))
   Vdata = hcat(ls, vdata(g))

   eit = edges(g)
   uls = encode(g, eit.us)
   vls = encode(g, eit.vs)

   Edata = hcat(uls, vls, edata(g))

   println(io, "$Nv,$Ne,$Ltype")
   println(io, join(Vprops, ','))
   println(io, join(Vtypes, ','))
   println(io, join(Eprops, ','))
   println(io, join(Etypes, ','))

   writedlm(io, Vdata, ',')
   writedlm(io, Edata, ',')
   nothing
end

function storegraph(g::Graph, filename::String)
   file = open(filename, "w")
   storegraph(g, file)
   close(file)
end