################################################# FILE DESCRIPTION #########################################################

# This file contains the edge descriptor, used for edge queries.

################################################# IMPORT/EXPORT ############################################################

export
# Types
EdgeDescriptor

################################################# INTERNAL IMPLEMENTATION ##################################################
""" Describes a subset of vertices and their properties """
type EdgeDescriptor
   g::Graph
   es
   props
end


# Constructor for Iterator
EdgeDescriptor(g::Graph) = EdgeDescriptor(g, edges(g), :)

# Edge Subset
EdgeDescriptor(x::EdgeDescriptor, e::EdgeID) = EdgeDescriptor(x.g, edge_subset(x, e), :)
EdgeDescriptor(x::EdgeDescriptor, es::AbstractVector{EdgeID}) = EdgeDescriptor(x, edge_subset(x, es), :)

EdgeDescriptor(x::EdgeDescriptor, is::Int) = EdgeDescriptor(x.g, edge_subset(x, is), :)
EdgeDescriptor(x::EdgeDescriptor, is::AbstractVector{Int}) = EdgeDescriptor(x.g, edge_subset(x, is), :)
EdgeDescriptor(x::EdgeDescriptor, is::Colon) = EdgeDescriptor(x.g, edge_subset(x, is), :)

# Property Subset
EdgeDescriptor(x::EdgeDescriptor, props) = EdgeDescriptor(x.g, deepcopy(x.es), property_subset(x, props))


################################################# PROPERTY UNION #############################################################

@inline function property_union!(x::EdgeDescriptor, prop)
   x.props = property_union(x, x.props, prop)
   nothing
end

@inline property_union(x::EdgeDescriptor, xprop, prop) = xprop == prop ? prop : vcat(xprop, prop)
@inline property_union(x::EdgeDescriptor, xprop::AbstractVector, prop) = in(prop, xprop) ? xprop : vcat(xprop, prop)
@inline property_union(x::EdgeDescriptor, xprop::Colon, prop) = vcat(listeprops(x.g), prop)
@inline property_union(x::EdgeDescriptor, xprop::Colon, ::Colon) = Colon()

################################################# SHOW ######################################################################

function display_edge_list(io::IO, x::EdgeDescriptor)
   props = x.props == Colon() ? sort(listeprops(x.g)) : sort(x.props)
   es = x.es == Colon() ? edges(x.g) : x.es
   es = isa(es, Pair) ? [es] : es

   rows = []
   push!(rows, ["Edge Label" map(string, props)...])

   n = length(es)
   if n <= 10
      for i in 1:min(n,10)
         push!(rows, [encode(x.g, es[i]) [string(geteprop(x.g, es[i], prop)) for prop in props]...])
      end
   else
      for i in 1:min(n,5)
         push!(rows, [encode(x.g, es[i]) [string(geteprop(x.g, es[i], prop)) for prop in props]...])
      end
      push!(rows, ["⋮", ["⋮" for prop in props]...])
      for i in n-5:n
         push!(rows, [encode(x.g, es[i]) [string(geteprop(x.g, es[i], prop)) for prop in props]...])
      end
   end
   drawbox(io, rows)
end

function Base.show(io::IO, x::EdgeDescriptor)
   display_edge_list(io, x)
end


################################################# ITERATION #################################################################

Base.length(x::EdgeDescriptor) = length(x.es)
Base.size(x::EdgeDescriptor) = (lenth(x),)

Base.start(x::EdgeDescriptor) = start(x.es)
Base.endof(x::EdgeDescriptor) = endof(x.es)

function Base.next(x::EdgeDescriptor, i0)
   e,i = next(x.es, i0)
   (encode(x.g, e), geteprop(x.g, e)), i
end
@inline Base.done(x::EdgeDescriptor, i) = done(x.es, i)


################################################# GETINDEX / SETINDEX #######################################################

# Unit getindex to search for a single label
Base.getindex(x::EdgeDescriptor, e::Pair) = EdgeDescriptor(x, resolve(x.g, e))
Base.getindex(x::EdgeDescriptor, label1, label2) = EdgeDescriptor(x, resolve(x.g, label1=>label2))

# Vector getindex for subset EdgeDescriptors
Base.getindex(x::EdgeDescriptor, is) = EdgeDescriptor(x, is)

# Setindex!
function Base.setindex!(x::EdgeDescriptor, val, propname)
   property_union!(x, propname)
   setvprop!(x.g, x.es, val, propname)
end

################################################# MAP #######################################################################

function Base.map!(f::Function, x::EdgeDescriptor, propname)
   property_union!(x, propname)
   seteprop!(x.g, x.es, f, propname)
end

################################################# SELECT ####################################################################

Base.select(x::EdgeDescriptor, props...) = EdgeDescriptor(x, collect(props))

Base.select!(x::EdgeDescriptor, props...) = property_union!(x, props)

################################################# FILTER ####################################################################

function Base.filter(x::EdgeDescriptor, conditions::ASCIIString...)
   es = edge_subset(x, :)
   for condition in conditions
      fn = parse_edge_query(condition)
      es = filter(e->fn(x.g, e...), es)
   end
   EdgeDescriptor(x.g, es, :)
end

function Base.filter!(x::EdgeDescriptor, conditions::ASCIIString...)
   for condition in conditions
      fn = parse_edge_query(condition)
      x.es = filter(e->fn(x.g, e...), x.es)
   end
   nothing
end