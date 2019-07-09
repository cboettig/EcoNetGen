Dear CRAN Maintainers,

This release fixes a bug that could allow generated average network degree larger than target on average.

I believe this also addresses the LTO checks that were added to CRAN at some stage after this package was last updated. I have done my best to follow the terse directions provided in the README.txt at https://www.stats.ox.ac.uk/pub/bdr/LTO/README.txt and to run R CMD check in a Ubuntu rchk container following Thomas Kalibera's guide at https://github.com/kalibera/rchk.

I think I've now patched the remaining LTO check issue now but I cannot be sure as I could not reproduce the additional warning on Thomas's rchk system. My apologies for the trouble and please let me know if things now look good from your end on the LTO checks.  
 

Sincerely,

Carl Boettiger
