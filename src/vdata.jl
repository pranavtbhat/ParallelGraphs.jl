################################################# FILE DESCRIPTION #########################################################

# This file contains the implementation of the Vertex DataFrame.

################################################# IMPORT/EXPORT ############################################################
export listvprops, hasvprop, getvprop, setvprop!


################################################# MUTATION #################################################################

function addvertex!(x::AbstractDataFrame)
   push!(x, @data fill(NA, ncol(x)))
   return
end

function rmvertex!(x::AbstractDataFrame, vs)
   if !isempty(x)
      deleterows!(x, vs)
   end
end

################################################# PROPERTY ACCESSORS #######################################################

listvprops(g::Graph) = names(vdata(g))

hasvprop(g::Graph, prop::Symbol) = haskey(vdata(g), prop)

################################################# GETVPROP #################################################################

"""
Retrieve vertex properties.

getvprop(g::Graph, v::VertexID, vprop::Symbol) -> Fetch the value of a property for vertex v
"""
getvprop(g::Graph, v::VertexID, vprop::Symbol) = vdata(g)[vprop][v]


""" getvprop(g::Graph, vs::VertexList, vprop::Symbol) -> Fetch the value of a property for v in vs """
getvprop(g::Graph, vs::VertexList, vprop::Symbol) = vdata(g)[vprop][vs]


""" getvprop(g::Graph, ::Colon, vprop::Symbol) -> Fetch the value of a property for all verices """
getvprop(g::Graph, ::Colon, vprop::Symbol) = vdata(g)[vprop][:]

################################################# SETVPROP #################################################################

"""
Set vertex properties.

setvprop!(g::Graph, v::VertexID, val(s), vprop::Symbol) -> Set a property for v
"""
function setvprop!(g::Graph, v::VertexID, val, vprop::Symbol)
   if hasvprop(g, vprop)
      vdata(g)[vprop][v] = val
   else
      error("Property $vprop doesn't exist. Please create it on all vertices first.")
   end
end

""" setvprop!(g::Graph, vs::VertexList, val(s), vprop::Symbol) -> Set a property for v in vs """
function setvprop!(g::Graph, vs::VertexList, val, vprop::Symbol)
   if hasvprop(g, vprop)
      vdata(g)[vprop][vs] = val
   else
      error("Property $vprop doesn't exist. Please create it on all vertices first.")
   end
end


""" setvprop!(g::Graph, ::Colon, val(s), vprop::Symbol) -> Set a property for all vertices in g """
function setvprop!(g::Graph, ::Colon, vals::AbstractVector, vprop::Symbol)
   if length(vals) == nv(g)
      vdata(g)[vprop] = vals
   else
      error("Trying to set $(length(vals)) values to $(nv(g)) properties")
   end
end

setvprop!(g::Graph, ::Colon, val, vprop::Symbol) = setvprop!(g, :, fill(val, nv(g)), vprop)

################################################# SUBGRAPHING ##############################################################

subgraph(x::AbstractDataFrame, vs::VertexList) = x[vs,:]

subgraph(x::AbstractDataFrame, vs::VertexList, vprops::Vector{Symbol}) = x[vs,vprops]
