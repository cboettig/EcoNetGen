! Program FortranNetGen.f90

! f2py -c --fcompiler=gnu95 -m FortranNetGen FortranNetGen.f90

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! module defining global variables
MODULE globals
  IMPLICIT double precision(A-H,O-Z)
  INTEGER, ALLOCATABLE, SAVE :: a(:,:)
  double precision, SAVE :: avk
  INTEGER, SAVE :: nmod,mmod,kmod,ntri1,ntri2,ntri3,nbi1,nbi2
  INTEGER, SAVE :: submodcut
END MODULE globals
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


SUBROUTINE subnetgen(output,n_modav,cutoffs,nettype,avkk,rewindprobs,mod_probs, modulecount)
USE globals
IMPLICIT double precision(A-H,O-Z)
INTEGER output(*)
INTEGER modulecount(*)
INTEGER, INTENT(IN), DIMENSION(2) :: n_modav
INTEGER, INTENT(IN), DIMENSION(2) :: cutoffs
INTEGER, INTENT(IN) :: nettype
double precision, INTENT(IN) :: avkk
double precision, INTENT(IN), DIMENSION(2) :: rewindprobs
double precision, INTENT(IN), DIMENSION(7) :: mod_probs
INTEGER, ALLOCATABLE :: degree(:)
INTEGER, DIMENSION(200) :: modsize_sav
CHARACTER*20 namenet
CHARACTER*50 name_network,prop_network,adj_network
double precision p1, p2, p3, p41, p42, p51, p52, prew, prewloc
double precision pc1, pc2, pc3, pc41, pc42, pc51, pc52, p, an, aux
namenet = "default"
n = n_modav(1)
modav = n_modav(2)
mcutoff = cutoffs(1)
submodcut = cutoffs(2)
p1 = mod_probs(1)
p2 = mod_probs(2)
p3 = mod_probs(3)
p41 = mod_probs(4)
p42 = mod_probs(5)
p51 = mod_probs(6)
p52 = mod_probs(7)
avk = avkk
prew = rewindprobs(1)
prewloc = rewindprobs(2)

! Set names for output files in the output_gen sub-directory:
! namenet_net.txt
! namenet_prop.txt
! namenet_adj.txt

name_network = "./output_gen/"//trim(namenet)//trim('_net.txt')
prop_network = "./output_gen/"//trim(namenet)//trim('_prop.txt')
adj_network = "./output_gen/"//trim(namenet)//trim('_adj.txt')


call rndstart()
!CALL init_random_seed()

! cummulative probabilies
pc1 = p1
pc2 = p1 + p2
pc3 = pc2 + p3
pc41 = pc3 + p41
pc42 = pc41 + p42
pc51 = pc42 + p51
pc52 = pc51 + p52

an = dble(n)

ALLOCATE (a(n,n),degree(n))

! Generate the Modular Network

a=0                  ! adjacency matrix
modtot = 0           ! keep track of network size as new modules are added
modtotold = 0        ! aux variable
modcount = 0         ! count number of modules
modsize_sav = 0      ! save size of each module

!write(6,*) '      module size','     module type'
!write(6,*) '----------------------------------------- '

do while(modtot < n)


    !! This one seems OKAY
    aux = unifrnd()
    !aux = unifrnd()

    modsize = int(modav*log(1.0D0/aux))
    if( modav == n) modsize = n         !if modsize = n build a single network

    if(modsize < mcutoff) then
        cycle                           !if modsize < mcutoff try again
  else if(n-modsize-modtot < mcutoff) then
    modsize = n - modtot            !last module is adjusted to be larger than mcutoff
  end if


    modtotold = modtot                 ! network size before adding module
    modtot = modtot + modsize          ! current network size
    modcount = modcount + 1            ! count modules
    modsize_sav(modcount) = modsize    ! save module size
    ini = modtot - modsize             ! initial position in the module is ini+1

    ! build network according to nettype
    !
    IF(nettype == 0) THEN
        !! This one seems okay too
        aux = unifrnd()
        !aux = unifrnd()   !choose module type
        IF(aux < pc1) THEN
            p = avk/dble(modsize-1)
            CALL RANDOMMOD(ini,modtot)
        ELSE IF(aux < pc2) THEN
            CALL SFMOD(ini,modtot)
        ELSE IF(aux < pc3) THEN
            CALL NESTEDMOD(ini,modtot)
        ELSE IF(aux < pc41) THEN
            CALL BINESTEDMOD(ini,modtot)
        ELSE IF(aux < pc42) THEN
            CALL BIRANDMOD(ini,modtot)
        ELSE IF(aux < pc51) THEN
            CALL TRIMOD(ini,modtot,1)
        ELSE IF(aux < pc52) THEN
            CALL TRIMOD(ini,modtot,2)
        END IF
    ELSE IF(nettype == 1) THEN
        CALL RANDOMMOD(ini,modtot)
    ELSE IF(nettype == 2) THEN
        CALL SFMOD(ini,modtot)
    ELSE IF(nettype == 3) THEN
        CALL NESTEDMOD(ini,modtot)
    ELSE IF(nettype == 41) THEN
        CALL BINESTEDMOD(ini,modtot)
    ELSE IF(nettype == 42) THEN
        CALL BIRANDMOD(ini,modtot)
    ELSE IF(nettype == 51) THEN
        CALL TRIMOD(ini,modtot,1)
    ELSE IF(nettype == 52) THEN
        CALL TRIMOD(ini,modtot,2)
    END IF
end do

! reconnect links within modules with probability prewloc
ini = 0
do k=1,modcount
    do i=1,modsize_sav(k)
        ii = i + ini
        do j=i+1,modsize_sav(k)
            jj = j + ini
            if(a(ii,jj) == 1) then
                !! this one seems okay
                aux = unifrnd()
                !aux = unifrnd()
                IF(aux < prewloc) THEN
                    a(ii,jj) = 0
                    a(jj,ii) = 0
                    !! This one causes SEGFAULT when changed to unifrnd
                    aux = unifrnd()
                    !aux = unifrnd()
                    ijp = int(modsize_sav(k)*aux)+1
                    ijpp = ijp + ini
                    aux = unifrnd()
                    if(aux < 0.5D0) then
                        a(ii,ijpp) = 1
                        a(ijpp,ii) = 1
                    else
                        a(ijpp,jj) = 1
                        a(jj,ijpp) = 1
                    end if
                END IF
            end if
        end do
    end do
    ini = ini + modsize_sav(k)
end do

! reconnect overall links to connect the modules with prew
do i=1,n
  do j=i+1,n
      if(a(i,j) == 1) then
          aux = unifrnd()
            IF(aux < prew) THEN
                a(i,j) = 0
                a(j,i) = 0
                !! SEGFAULT HERE if changed to unifrnd
                aux = unifrnd()
                ijp = int(n*aux)+1
                aux = unifrnd()
                if(aux < 0.5D0) then
                    a(i,ijp) = 1
                    a(ijp,i) = 1
                else
                    a(ijp,j) = 1
                    a(j,ijp) = 1
                end if
            END IF
        end if
    end do
end do

! check for disconnected nodes and randomly reconnect them
degree = sum(a,dim=1)
do i=1,n
  if(degree(i) == 0) then
    jp = i
    do while (jp == i)
     !! Segfault when changed
      aux = unifrnd()
      jp = int(n*aux)+1
        a(i,jp) = 1
        a(jp,i) = 1
    end do
    end if
end do




! average connectivity
icon = SUM(a)

call clusters(a,n,maxsize,nclusters)


if (nclusters /= 1) then
!    write(6,*)
!    write(6,*) 'WARNING: THE NETWORK HAS MORE THAN ONE CONNECTED COMPONENT'
!    write(6,*) 'RUN THE PROGRAM AGAIN UNTIL A SINGLE COMPONENT IS OBTAINED'
!    write(6,*) 'TRY INCREASING THE REWIRING PROBABILIES'
!    write(6,*)
end if

modulecount(1) = modcount

do i=1,n
  do j=1,n
    output(i + (j-1) * n) = a(i,j)
  end do
end do

DEALLOCATE(a,degree)

call rndend()

end subroutine SubNetGen

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE RANDOMMOD(ini,modtot)
USE globals
double precision p
iini = ini + 1
ifin = modtot
modsize = ifin - ini
p = avk/dble(modsize-1)

call rndstart()


do i=iini,ifin
  do j=i+1,ifin
    aux = unifrnd()
      if( aux < p) then
                a(i,j) = 1
                a(j,i) = 1
            end if
  end do
end do

call rndend()

return
end

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE SFMOD(ini,modtot)
USE globals
IMPLICIT double precision(A-H,O-Z)
INTEGER, ALLOCATABLE ::  co(:),sco(:),id(:),b(:,:)
INTEGER sm
modsize = modtot - ini
m = int(avk/2.0)
m0 = m+1
ALLOCATE (b(modsize,modsize))
ALLOCATE (co(modsize),sco(modsize),id(m))
! generate initially fully connected cluster
co=0; b=0;
pinit = 1.0D0

call rndstart()



do i=1,m0-1
    do k=i+1,m0
        aux2 = unifrnd()
        if(aux2 < pinit) then
            b(i,k) = 1
        end if
    end do
end do
b(1:m0,1:m0) = b(1:m0,1:m0) + transpose(b(1:m0,1:m0))
co(1:m0) = sum(b(1:m0,1:m0),1)
!  START ADDING NODES
do l=m0,modsize-1
!--------------- Preference ---------------
    sm = 0 ; sco = 0
    do i=1,l
        sm = co(i) + sm
        sco(i) = sm  ! vector of partial sums of con/vities
    end do
    k = 1
3  do
        aux2 = unifrnd()
        j = int(aux2*sco(l)) + 1  ! Random integer in [1, sum of all cone/ties]
        id(k:k) = minloc(abs(sco - j))
        if ( sco(id(k)) < j )  id(k) = id(k) + 1
        if ( id(k) > modsize) go to 3
        do i=1,k-1
            if (id(i) == id(k)) go to 3
        end do
        k = k + 1
        if (k > m) exit
    end do
!--------------- Attachment -----------------
    do j=1,m
        i = id(j)
        IF(aux2 < 0.5D0) THEN
            i1=i;l1=l+1
        ELSE
            i1=l+1;l1=i
        END IF
        co(i1) = co(i1) + 1
        b(i1,l1) = 1
        b(l1,i1) = 1
        co(l1) = co(l1) + 1
    end do
end do
! place network b as a block in network a
do i=1,modsize
  do j=1,modsize
    a(ini+i,ini+j) = b(i,j)
  end do
end do

call rndend()

DEALLOCATE(b,co,sco,id)
return
end

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE NESTEDMOD(ini,modtot)
USE globals
IMPLICIT double precision(A-H,O-Z)
double precision alpha
ifin = modtot
modsize = ifin-ini
alpha = log(1.0D0+2.0D0/avk)  ! populate module
do i=1,modsize
  n1 = int(modsize*exp(-alpha*(i-1)))
  do j=i+1,n1
    a(ini+i,ini+j) = 1
    a(ini+j,ini+i) = 1
  end do
end do

return
end

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE BINESTEDMOD(ini,modtot)
USE globals
IMPLICIT double precision(A-H,O-Z)
double precision eps, alpha

call rndstart()

modsize = modtot-ini
nmod = 0
DO while(nmod < submodcut)
  aux = unifrnd()   !split module in two similar blocks
  eps = 0.5D0 + 0.2d0*(aux-0.5d0)
  nmod = int(eps*modsize)
  mmod = modsize - nmod
END DO
alpha = log(1.0d0+1.0d0/(avk-1.0d0))
do i=1,nmod
  n1 = int(mmod*exp(-alpha*(i-1)))
  do j=1,n1
    a(ini+i,ini+j+nmod) = 1
    a(ini+j+nmod,ini+i) = 1
  end do
end do
nbi1 = nmod
nbi2 = mmod

call rndend()

return
end


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE BIRANDMOD(ini,modtot)
USE globals
IMPLICIT double precision(A-H,O-Z)
double precision eps, p
modsize = modtot-ini
nmod = 0

call rndstart()

DO while(nmod < submodcut)
    aux = unifrnd()   !split module in two similar blocks
    eps = 0.5d0 + 0.2d0*(aux-0.5d0)
    nmod = int(eps*modsize)
    mmod = modsize - nmod
END DO
ini1 = ini + 1
ifin1 = ini1 + nmod
p = 2.0d0*avk/dble(modsize-1)
do i=ini1,ifin1
    do j=ifin1+1,modtot
        aux = unifrnd()
        if( aux < p) then
            a(i,j) = 1
            a(j,i) = 1
        end if
    end do
end do
nbi1 = nmod
nbi2 = mmod

call rndend()

return
end


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE TRIMOD(ini,modtot,nett)
USE globals
IMPLICIT double precision(A-H,O-Z)
double precision eps, aux

call rndstart()

modsize = modtot-ini
! define block sizes
aux = unifrnd()   !split network in two parts 2/3 + 1/3
eps = 0.66d0 + 0.2d0*(aux-0.5d0)
imod = int(eps*modsize)
kmod = modsize - imod
! first module is a bi-partite network with sizes nmod, mmod
CALL BINESTEDMOD(ini,modtot-kmod)
ntri1 = nmod
ntri2 = mmod
ntri3 = kmod
! last module connects with second module (ini = nmod)
IF(nett == 1) THEN
    CALL BIRANDMOD(ini+nmod,modtot)
ELSE IF(nett == 2) THEN
    CALL BINESTEDMOD(ini+nmod,modtot)
END IF

call rndend()

return
end



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE clusters(jj,nf,maxsize,icount)
INTEGER nf,i,j,nvm(1)
INTEGER jj(nf,nf),vm(nf+1)
INTEGER, ALLOCATABLE :: csizes(:)

ALLOCATE (csizes(0:nf))
nvm(1) = 1
icount = 0
csizes = 0
itot = 0

do while (nvm(1) /= nf+1)
if(itot == 0) then
vm = 0
vm(1) = 1
i = 1
else
loop1: do i=1,nf
do j=1,nvm(1)-1
if(i == vm(j)) cycle loop1
end do
vm(nvm(1)) = i
exit loop1
end do loop1
end if
CALL findtree(jj,vm,vm(nvm(1)),nf,nvm)
nvm(1:1) = minloc(vm)
icount = icount + 1
csizes(icount) = nvm(1)-1 - itot
itot = itot + csizes(icount)
end do
maxsize = maxval(csizes)
END SUBROUTINE clusters


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
RECURSIVE SUBROUTINE findtree(jj,vm,n,nf,nvm)
  INTEGER, INTENT(IN) :: n
  INTEGER i,j,nvm(1),m
  INTEGER jj(nf,nf),v(nf),vm(nf+1)
  ! find neighbors of node n
  CALL findneighbors (jj,n,nf,v,m)
  nvm(1:1) = minloc(vm) - 1
  loop1: DO i=1,m
  DO j=1,nvm(1)
  IF(v(i) == vm(j)) THEN
  CYCLE loop1
  END IF
  END DO
  IF(nvm(1)==nf) EXIT loop1
  nvm(1) = nvm(1) + 1
  vm(nvm(1)) = v(i)
  CALL findtree(jj,vm,v(i),nf,nvm)
  END DO loop1
  RETURN
END


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE findneighbors (jj,n,nf,v,m)
  INTEGER n,nf,i,m
  INTEGER jj(nf,nf),v(nf)
  m = 0
  DO i=1,nf
    IF(jj(n,i)==1) THEN   !find neighbors of node n
      m = m + 1         !add 1 to counter
      v(m) = i          !store neighbor
    END IF
  END DO
  RETURN
END



!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE init_random_seed()
INTEGER :: i, n, clock
INTEGER, DIMENSION(:), ALLOCATABLE :: seed
CALL RANDOM_SEED(size = n)
ALLOCATE(seed(n))
CALL SYSTEM_CLOCK(COUNT=clock)
seed = clock + 37 * (/ (i - 1, i = 1, n) /)
CALL RANDOM_SEED(PUT = seed)
DEALLOCATE(seed)
END SUBROUTINE
