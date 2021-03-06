#ifdef time_mean_sbc_data
      subroutine atmos
c
c-----------------------------------------------------------------------
c     this "atmos" model is an EXAMPLE of how to supply MOM with surface
c     boundary conditions which are a function of latitude and
c     longitude but NOT of time.
c
c     author:      r. c. pacanowski      e-mail=> rcp@gfdl.gov
c    (mpp items)   v. balaji             e-mail=> vb@gfdl.gov
c-----------------------------------------------------------------------
c
      use mom3_mpp_mod
      use sbc_info
      use sbc_ocean
# include "param.h"
# if defined sponges && !defined sponges_old
      use xsponge_mod
# endif
      character*32 astamp
      dimension xxt(imt), yyt(jmt), xxu(imt), yyu(jmt)
      common /catmos/ sst(imt,jmt), sss(imt,jmt)
c
c
c-----------------------------------------------------------------------
c     Work on all rows assuming S.B.C. arrays are (imt,jmt)
c-----------------------------------------------------------------------
c
      joff = 0
      js   = 1
      je   = jmt
c
c-----------------------------------------------------------------------
c     get indices related to S.B.C.
c     ordering of S.B.C. was set in driver.F 
c-----------------------------------------------------------------------
c
      itaux = index_of_sbc ('taux')
      itauy = index_of_sbc ('tauy')
      ihflx = index_of_sbc ('heatflux')
      ipme  = index_of_sbc ('saltflux')
      isst  = index_of_sbc ('sst')
      isss  = index_of_sbc ('sss')
c
      if (afirst) then
c
c-----------------------------------------------------------------------
c       on the first call to "atmos", read the time mean data "taux" 
c       and "tauy" along with the time mean SST and SSS for restoring
c       surface tracers. It is assumed that this data has been prepared
c       with the run scripts in PREP_DATA
c-----------------------------------------------------------------------
c
        call getunit (nutaux, 'taux.mom'
     &,               'unformatted sequential rewind ieee')
        call getunit (nutauy, 'tauy.mom'
     &,               'unformatted sequential rewind ieee')
        call getunit (nusst, 'sst.mom'
     &,               'unformatted sequential rewind ieee')
        call getunit (nusss, 'sss.mom'
     &,               'unformatted sequential rewind ieee')
c
c-----------------------------------------------------------------------
c       skip the monthly values and read the annual means
c-----------------------------------------------------------------------
c
        do n=1,12
          read (nutaux)
          read (nutaux)
c
          read (nutauy)
          read (nutauy)
c
	  read (nusst)
	  read (nusst)
c
	  read (nusss)
	  read (nusss)
        enddo
c
c       annual mean surface wind stress components (13th record)
c
        read (nutaux)
        read (nutaux) astamp, dpm, iimt, jjmt, nn, xxu, yyu, sst
        do j=1,jmt
	  do i=1,imt
	    sbcocn(i,j,itaux) = sst(i,j)
	  enddo
	enddo
        write (stdout,'(/a,g14.7,a/)')
     & ' initilized annual mean taux. annual period=',dpm, 'days'
        read (nutauy)
        read (nutauy) astamp, dpm, iimt, ijmt, nn, xxu, yyu, sst
        do j=1,jmt
	  do i=1,imt
	    sbcocn(i,j,itauy) = sst(i,j)
	  enddo
	enddo
        write (stdout,'(/a,g14.7,a/)')
     & ' initilized annual mean tauy. annual period=',dpm, 'days'
# if defined sponges && !defined sponges_old
        do jrow = 2,j_south_spng-2
	  do i=1,imt
	    sbcocn(i,jrow,itaux) = sbcocn(i,j_south_spng-1,itaux)
	    sbcocn(i,jrow,itauy) = sbcocn(i,j_south_spng-1,itauy)
	  enddo
	  write (stdout,*) '=>Note: resetting stress on row'
     &,   jrow,' to stress on row', j_south_spng-1
	enddo
        do jrow = j_north_spng+1,jmt-1
	  do i=1,imt
	    sbcocn(i,jrow,itaux) = sbcocn(i,j_north_spng,itaux)
	    sbcocn(i,jrow,itauy) = sbcocn(i,j_north_spng,itauy)
	  enddo
	  write (stdout,*) '=>Note: resetting stress on row'
     &,   jrow,' to stress on row', j_north_spng
	enddo
# endif
c
c       annual mean SST and SSS  (13th record)
c
        read (nusst)
        read (nusst) astamp, dpm, iimt, ijmt, k, zp, nn, xxt, yyt, sst
        write (stdout,'(/a,g14.7,a/)')
     & ' initilized annual mean SST. annual period=',dpm, 'days'
        read (nusss)
        read (nusss) astamp, dpm, iimt, ijmt, k, zp, nn, xxt, yyt, sss
#ifdef salinity_psu            
        do i=1,imt
          do j=1,jmt
            if (sss(i,j) .ne. 0.0) then
              sss(i,j) = sss(i,j)*1.e3 + 35.0
            endif
          enddo
        enddo
#endif
        write (stdout,'(/a,g14.7,a/)')
     & ' initilized annual mean SSS. annual period=',dpm, 'days'
c
# if defined sponges && !defined sponges_old
        do jrow = 2,j_south_spng-1
	  do i=1,imt
	    sst(i,jrow) = sst(i,j_south_spng)
	    sss(i,jrow) = sss(i,j_south_spng)
	  enddo
	  write (stdout,*)
     &    '=>Note: resetting SST & SSS on row'
     &,   jrow,' to SST & SSS on row', j_south_spng
	enddo
        do jrow = j_north_spng+1,jmt-1
	  do i=1,imt
	    sst(i,jrow) = sst(i,j_north_spng)
	    sss(i,jrow) = sss(i,j_north_spng)
	  enddo
	  write (stdout,*)
     &    '=>Note: resetting SST & SSS on row'
     &,   jrow,' to SST & SSS on row', j_north_spng
	enddo
# endif
        call print_checksum (sbcocn(1,1,isst), imt, jmt
     &,                    ' checksum for annual mean isst =')
        call print_checksum (sbcocn(1,1,isss), imt, jmt
     &,                    ' checksum for annual mean isss =')
        call print_checksum (sbcocn(1,1,itaux), imt, jmt
     &,                    ' checksum for annual mean taux =')
        call print_checksum (sbcocn(1,1,itauy), imt, jmt
     &,                    ' checksum for annual mean tauy =')
        call print_checksum (sst, imt, jmt
     &,                    ' checksum for annual mean sst =')
        call print_checksum (sss, imt, jmt
     &,                    ' checksum for annual mean sss =')
c
        call relunit (nutaux)
        call relunit (nutauy)
        call relunit (nusst)
        call relunit (nusss)
      endif
      call mpp_sync()
c
c----------------------------------------------------------------------
c     Taux and Tauy don`t change with time, but heatflux and saltflux
c     may change if restoring SST and SSS to time mean data
c----------------------------------------------------------------------
c
      do j=js,je
        jrow = j + joff
# ifdef restorst
c
c       restore surface tracers to prescribed data using a newtonian
c       damping term with a restoring time scale of "dampts" (days)
c       (which is set via namelist).
c
c
	if (isst .ne. 0 .and. ihflx .ne. 0) then
	  do i=2,imtm1
	    sbcocn(i,jrow,ihflx) = damp_factor(1)*
     &                             (sst(i,jrow) - sbcocn(i,jrow,isst))
          enddo
        endif
	if (isss .ne. 0 .and. ipme .ne. 0) then
	  do i=2,imtm1
	    sbcocn(i,jrow,ipme) = damp_factor(2)*
     &                            (sss(i,jrow) - sbcocn(i,jrow,isss))
          enddo
        endif
# else
c
c       supply zero heat flux and salt flux
c
        if (ihflx .ne. 0) then
          do i=1,imt
            sbcocn(i,jrow,ihflx) = c0
          enddo
        endif
        if (ipme .ne. 0) then
          do i=1,imt
            sbcocn(i,jrow,ipme) = c0
          enddo
        endif
# endif
      enddo
c
      return
      end
#else
      subroutine nodataatmos
      return
      end
#endif
