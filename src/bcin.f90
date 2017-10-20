subroutine bcin

  use types
  use parameters
  use geometry
  use variables

  implicit none

  integer :: i,ini,ino,iface
  real(dp) :: uav,outare
  real(dp) :: flowen, flowte, flowed
  real(dp) :: are


  flomas = 0.0_dp 
  flomom = 0.0_dp
  flowen = 0.0_dp
  flowte = 0.0_dp
  flowed = 0.0_dp

  if(ninl.gt.0) then

    ! Loop over inlet boundaries
    do i = 1,ninl
      iface = iInletFacesStart+i
      ini = iInletStart + i

      ! Example of generating inflow profile for one case (Ishihara hill)
      ! The numbers are then copied to 0/U file, under inlet \ nonuniform \ <list of values>
      ! write(6,'(f9.6,1x,f3.1,1x,f3.1)') 5.5d0*(zf(iface)/0.2d0)**0.135,zero,zero  

      vis(ini) = viscos

      fmi(i) = den(ini)*(arx(iface)*u(ini)+ary(iface)*v(ini)+arz(iface)*w(ini))

      ! Face normal vector is faced outwards, while velocity vector at inlet
      ! is faced inwards. That means their scalar product will be negative,
      ! so minus signs here is to turn net mass influx - flomas, into positive value.
      flomas = flomas - fmi(i) 

      flomom = flomom + abs(fmi(i))*sqrt(u(ini)**2+v(ini)**2+w(ini)**2)

      flowen = flowen + abs(fmi(i)*t(ini))

      flowte = flowte + abs(fmi(i)*te(ini))

      flowed = flowed + abs(fmi(i)*ed(ini))

    enddo

    ! Loop over outlet boundaries

    ! Outlet area
    outare = 0.0_dp
    do i = 1,nout
      iface = iOutletFacesStart + i
      outare = outare + sqrt(arx(iface)**2+ary(iface)**2+arz(iface)**2)
    enddo

    ! Average velocity at outlet boundary
    uav = flomas/(densit*outare+small)

    ! Mass flow trough outlet faces using Uav velocity
    do i = 1,nout
      iface = iOutletFacesStart + i
      ino = iOutletStart + i

      are = sqrt(arx(iface)**2+ary(iface)**2+arz(iface)**2)

      u(ino) = uav * arx(iface)/are
      v(ino) = uav * ary(iface)/are
      w(ino) = uav * arz(iface)/are

      !fmo(i)=den(ino)*uav*(Xno(i)+Yno(i)+Zno(i)) ! Originalno u caffa kodu.
      fmo(i)=den(ino)*(arx(iface)*u(ino)+ary(iface)*v(ino)+arz(iface)*w(ino))

    enddo

    write ( *, '(a)' ) '  Inlet boundary condition information:'
    write ( *, '(a)' ) ' '
    write ( *, '(a,e12.6)' ) '  Mass inflow: ', flomas
    write ( *, '(a,e12.6)' ) '  Momentum inflow: ', flomom

  else

    ! No inflow into the domain: eg. natural convection case, etc.
    flomas=1.0_dp
    flomom=1.0_dp
    flowen = 1.0_dp
    flowte=1.0_dp
    flowed=1.0_dp

  endif



  ! Initialization of residual for all variables
  do i=1,nphi
    rnor(i) = 1.0_dp
    resor(i) = 0.0_dp
  enddo

  rnor(iu)    = 1.0_dp/(flomom+small)
  rnor(iv)    = rnor(iu)
  rnor(iw)    = rnor(iu)

  rnor(ip)    = 1.0_dp/(flomas+small)
  rnor(ite)   = 1.0_dp/(flowte+small)
  rnor(ied)   = 1.0_dp/(flowed+small)


  ! Correct turbulence at inlet for appropriate turbulence model
  if(lturb) call correct_turbulence_inlet()

end subroutine