!
!  Copyright 2016 ARTED developers
!
!  Licensed under the Apache License, Version 2.0 (the "License");
!  you may not use this file except in compliance with the License.
!  You may obtain a copy of the License at
!
!      http://www.apache.org/licenses/LICENSE-2.0
!
!  Unless required by applicable law or agreed to in writing, software
!  distributed under the License is distributed on an "AS IS" BASIS,
!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!  See the License for the specific language governing permissions and
!  limitations under the License.
!

!===============================================================
real(8) function bessel_j1(x)
  implicit none
  real(8), intent(in) :: x
  integer, parameter :: order = 30
  real(8) :: c, s
  integer :: m

  c = 0.5 * x
  s = c
  do m = 1, 30
    c = -0.25 * x * x / (m * (m + 1)) * c
    s = s + c
  end do
  bessel_j1 = s
  return
end function bessel_j1
!===============================================================
real(8) function sin2cos(t, tw, omega, cep)
  use Global_Variables, only: pi
  implicit none
  real(8), intent(in) :: t, tw, omega, cep
  real(8) :: theta1, theta2

  if ((0 <= t) .and. (t <= tw)) then
    theta1 = pi / tw * t
    theta2 = omega * t + 2 * pi * cep
    sin2cos = sin(theta1) ** 2 * cos(theta2)
  else
    sin2cos = 0.0
  endif
  return
end function sin2cos
!===============================================================
subroutine incident_bessel_beam()
  use Global_Variables, only: IWcm2_1, omegaeV_1, tpulsefs_1, Epdir_1, phi_CEP_1, &
                            & NXvacL_m, NXvacR_m, NYvacB_m, NYvacT_m, &
                            & HX_m, HY_m, Ac_m, Ac_new_m, dt, &
                            & pi, c_light
  implicit none
  real(8) :: f0_1, omega_1, tpulse_1, wpulse_1
  integer :: ix_m, iy_m
  real(8) :: lx, ly, x, y, kx, ky, k, vx
  real(8) :: f(3), j, tau
  
  real(8) bessel_j1, sin2cos
  
  ! First pulse
  f0_1 = 5.338d-9*sqrt(IWcm2_1)  ! electric field in a.u.
  omega_1 = omegaeV_1 / (2d0*13.6058d0)  ! frequency in a.u.
  tpulse_1 = tpulsefs_1 / 0.02418d0 ! pulse_duration in a.u.
  wpulse_1 = 2*pi/tpulse_1

  lx = (NXvacR_m-NXvacL_m) * HX_m
  ly = NYvacT_m * HY_m

  ky = 3.8317 / ly
  k = omega_1 / c_light
  
  if (ky > k) then
    call err_finalize('Error: NY,HY is not enough')
  endif
  
  kx = SQRT(k*k-ky*ky)
  vx = omega_1 / kx

  Ac_m = 0.0
  Ac_new_m = 0.0
  do iy_m = NYvacB_m, NYvacT_m
     y = HY_m * (iy_m - 0.5)
     j = bessel_j1(ky * y)
     f = j * f0_1 / 0.58186 * Epdir_1
     do ix_m = NXvacL_m-1, 0
       x = ix_m * HX_m
       ! Ac_new_m
       tau = - x / vx
       Ac_new_m(:,ix_m,iy_m) = f * sin2cos(tau, tpulse_1, omega_1, phi_CEP_1)
       ! Ac_m (previous time-step)
       tau = - x / vx - dt
       Ac_m(:,ix_m,iy_m) =  f * sin2cos(tau, tpulse_1, omega_1, phi_CEP_1)
     end do
  end do
  
  ! impose boundary condition
  Ac_new_m(:,:,NYvacT_m+1) = 0.0
  Ac_new_m(:,:,NYvacB_m-1) = Ac_new_m(:,:,NYvacB_m)
  Ac_m(:,:,NYvacT_m+1) = 0.0
  Ac_m(:,:,NYvacB_m-1) = Ac_m(:,:,NYvacB_m)
  return
end subroutine incident_bessel_beam
