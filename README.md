EcoNetGen
================

[![Travis-CI Build
Status](https://travis-ci.org/cboettig/EcoNetGen.svg?branch=master)](https://travis-ci.org/cboettig/EcoNetGen)
[![AppVeyor Build
Status](https://ci.appveyor.com/api/projects/status/github/cboettig/EcoNetGen?branch=master&svg=true)](https://ci.appveyor.com/project/cboettig/EcoNetGen)
[![Coverage
Status](https://img.shields.io/codecov/c/github/cboettig/EcoNetGen/master.svg)](https://codecov.io/github/cboettig/EcoNetGen?branch=master)
[![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/EcoNetGen)](https://cran.r-project.org/package=EcoNetGen)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![downloads](https://cranlogs.r-pkg.org/badges/grand-total/netgen)](https://github.com/metacran/cranlogs.app)
[![DOI](https://zenodo.org/badge/116610054.svg)](https://zenodo.org/badge/latestdoi/116610054)

<!-- README.md is generated from README.Rmd. Please edit that file -->

`EcoNetGen` lets you randomly generate a wide range of interaction
networks with specified size, average degree, modularity, and
topological structure. You can also sample nodes and links from within
simulated networks randomly, by degree, by module, or by abundance.
Simulations and sampling routines are implemented in FORTRAN, providing
efficient generation times even for large networks. Basic visualization
methods also included. Algorithms implemented here are described in de
Aguiar et al. (2017)
[arXiv:1708.01242](https://arxiv.org/abs/1708.01242).

## Installation

`EcoNetGen` is now on CRAN and can be installed in the usual way:

``` r
install.packages("EcoNetGen")
```

See [NEWS](NEWS.md) for a list of the most recent changes to the
development version and current CRAN release. You can install the
current development version of `EcoNetGen` from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("cboettig/EcoNetGen")
```

This way requires you have a recent FORTRAN compiler available on your
machine.

## Randomly generate networks

This is a basic example which generates a network. See `?netgen` for
documentation describing the parameter arguments. Setting `verbose =
FALSE` (default) suppresses the output summary message.

``` r
library(EcoNetGen)
set.seed(123456) # for a reproducible simulation

network <- netgen(net_size = 150,
                  ave_module_size = 20, 
                  min_module_size = 10,
                  min_submod_size = 5,
                  net_type = "bi-partite nested",
                  ave_degree = 10,
                  verbose = TRUE
                  ) 
#> 
#> module count = 8 
#> average degree = 6.10666666666667 
#> average module size = 18.75 
#> number of components = 1 
#> size of largest component = 150
```

We can plot the resulting `igraph` as an adjacency matrix:

``` r
adj_plot(network)
```

![](man/figures/README-adj_plot-1.png)<!-- -->

Network `igraph` objects can also be plotted using the standard `igraph`
plotting routines, for example:

``` r
library(igraph)
plot(network, vertex.size= 0, vertex.label=NA, 
     edge.color = rgb(.22,0,1,.02), vertex.shape="none", 
     edge.curved =TRUE, layout = layout_with_kk)
```

![](man/figures/README-igraph_plot-1.png)<!-- -->

## Sample from a network

``` r
set.seed(123456) # for a reproducible random sampling
sampled <- netsampler(network, 
                     key_nodes_sampler = "degree", 
                     neighbors_sampler = "random",
                     n_key_nodes = 50,
                     n_neighbors = 0.5 # 50%
                    )
```

We can plot the adjacency network, coloring red the sampled nodes. Note
that `adj_plot` objects are just `ggplot` graphs (`geom_raster`) under
the hood, and can be modified with the usual `ggplot` arguments, such as
adding a title and changing the color theme here.

``` r
library(ggplot2) # needed to modify plot

adj_plot(sampled) + 
  ggtitle("Adjacency matrix of sampled vs full network") + 
  scale_fill_manual(values = c("#ED4E33", "#3B7EA1"))
```

![](man/figures/README-sampled_adj-1.png)<!-- -->

Don’t forget to check out the `ggraph` package, which isn’t required for
`EcoNetGen` but provides a lot of additional great ways to plot your
network. Here we plot the simulated network color-coding the sampled
nodes and edges (indicated by the label “sampled” on vertices and
edges):

``` r
library(ggraph)
ggraph(sampled, layout = 'kk') +
        geom_edge_link(aes(color = label), alpha=0.4) +
        geom_node_point(aes(color = label)) +
        theme_graph() + 
        scale_color_manual(values = c("#ED4E33", "#3B7EA1")) + 
        scale_edge_color_manual(values = c("#ED4E33", "#3B7EA1"))
```

![](man/figures/README-sampled_hairball-1.png)<!-- -->

Or extract and plot just the sampled network:

``` r
subnet <- subgraph.edges(sampled, 
                         E(sampled)[label=="sampled"])

ggraph(subnet, layout = 'graphopt') +
        geom_edge_link(alpha=0.4) +
        geom_node_point() +
        theme_graph() 
```

![](man/figures/README-subgraph-1.png)<!-- -->

## A few example statistics

And we can compute common statistics from `igraph` as well. Here we
confirm that clustering by “edge betweeness” gives us the expected
number of modules:

``` r
community <- cluster_edge_betweenness(as.undirected(network))
length(groups(community))
#> [1] 8
```

We can check the size of each module as well:

``` r
module_sizes <- sizes(community)
module_sizes
#> Community sizes
#>  1  2  3  4  5  6  7  8 
#> 18 18 19 22 19 32 11 11
```

Average degree:

``` r
mean(degree(as.undirected(network)))
#> [1] 6.12
```

We can also label and plot the cluster membership:

``` r
V(sampled)$module <- as.character(membership(community))
```

``` r
ggraph(sampled, layout = 'kk') +
  geom_edge_link(alpha=0.1) +
  geom_node_point(aes(colour = module)) + 
  theme_graph()
```

![](man/figures/README-members-1.png)<!-- -->
