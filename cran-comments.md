Dear CRAN Maintainers,

This release fixes a bug that could allow generated average network degree larger than target on average.

I believe this also addresses the LTO checks that were added to CRAN at some stage after this package was last updated. I have done my best to follow the terse directions provided in the README.txt at https://www.stats.ox.ac.uk/pub/bdr/LTO/README.txt and to run R CMD check in a Ubuntu rchk container following Thomas Kalibera's guide at https://github.com/kalibera/rchk.

This includes the LTO fix kindly provided by Professor Ripley.  Please convey my thanks!

Sincerely,

Carl Boettiger
