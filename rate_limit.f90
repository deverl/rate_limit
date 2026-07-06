! Should rate limit
! 4 cases
!   1: key not in cache (create new entry, count = 1, return false)
!   2: key in cache, not expired, count < max (increment count, return false)
!   3. key in cache, not expired, count >= max (return true)
!   4. key in cache, expired (create new entry, count = 1, return false)

module sleep_mod
    use iso_c_binding, only: c_int
    implicit none
    private
    public :: sleep_ms

    interface
        function c_usleep(usec) bind(c, name="usleep") result(rc)
            import :: c_int
            integer(c_int), value :: usec
            integer(c_int) :: rc
        end function c_usleep
    end interface

contains

    subroutine sleep_ms(ms)
        integer, intent(in) :: ms
        integer(c_int) :: rc
        rc = c_usleep(int(ms * 1000, c_int))
    end subroutine sleep_ms

end module sleep_mod


module rate_limiter
    implicit none
    private
    public :: rate_limit

    integer, parameter :: dp = kind(1.0d0)

    ! Fortran has no standard library hash map, so the cache is a small
    ! hash table with separate chaining.
    integer, parameter :: num_buckets = 64

    ! Sweep expired entries every Nth rate_limit call so stale keys
    ! don't accumulate forever.
    integer, parameter :: evict_every = 100

    type :: entry_t
        character(len=:), allocatable :: key
        real(dp) :: end_time        ! Window end time (monotonic seconds)
        integer :: count            ! Requests seen in the current window
        type(entry_t), pointer :: next => null()
    end type entry_t

    type :: bucket_t
        type(entry_t), pointer :: head => null()
    end type bucket_t

    type(bucket_t), save :: cache(num_buckets)
    integer(8), save :: call_count = 0

contains

    ! Monotonic clock (seconds): unaffected by system clock adjustments,
    ! with sub-second precision.
    function monotonic_time() result(t)
        real(dp) :: t
        integer(8) :: ticks, rate
        call system_clock(ticks, rate)
        t = real(ticks, dp) / real(rate, dp)
    end function monotonic_time

    ! djb2 string hash (kept below 2**31 to avoid integer overflow)
    function hash_key(key) result(bucket)
        character(*), intent(in) :: key
        integer :: bucket
        integer(8) :: h
        integer :: i
        h = 5381
        do i = 1, len(key)
            h = mod(h * 33 + iachar(key(i:i)), 2147483648_8)
        end do
        bucket = int(mod(h, int(num_buckets, 8))) + 1
    end function hash_key

    function find_entry(key) result(e)
        character(*), intent(in) :: key
        type(entry_t), pointer :: e
        e => cache(hash_key(key))%head
        do while (associated(e))
            if (e%key == key) return
            e => e%next
        end do
    end function find_entry

    subroutine add_entry(key, end_time, count)
        character(*), intent(in) :: key
        real(dp), intent(in) :: end_time
        integer, intent(in) :: count
        integer :: bucket
        type(entry_t), pointer :: e
        bucket = hash_key(key)
        allocate(e)
        e%key = key
        e%end_time = end_time
        e%count = count
        e%next => cache(bucket)%head
        cache(bucket)%head => e
    end subroutine add_entry

    subroutine evict_expired()
        real(dp) :: t
        integer :: bucket
        type(entry_t), pointer :: e, prev, dead
        t = monotonic_time()
        do bucket = 1, num_buckets
            prev => null()
            e => cache(bucket)%head
            do while (associated(e))
                if (t >= e%end_time) then
                    dead => e
                    e => e%next
                    if (associated(prev)) then
                        prev%next => e
                    else
                        cache(bucket)%head => e
                    end if
                    deallocate(dead)
                else
                    prev => e
                    e => e%next
                end if
            end do
        end do
    end subroutine evict_expired

    function rate_limit(key, interval, max_count) result(limited)
        character(*), intent(in) :: key
        integer, intent(in) :: interval, max_count
        logical :: limited
        real(dp) :: t
        type(entry_t), pointer :: e

        call_count = call_count + 1
        if (mod(call_count, int(evict_every, 8)) == 0) then
            call evict_expired()
        end if

        t = monotonic_time()
        e => find_entry(key)

        if (.not. associated(e)) then
            ! Case 1
            call add_entry(key, t + interval, 1)
            limited = .false.
            return
        end if

        if (t < e%end_time) then
            ! Not expired.
            if (e%count < max_count) then
                ! Case 2
                e%count = e%count + 1
                limited = .false.
                return
            end if

            ! Case 3
            limited = .true.
            return
        end if

        ! Case 4
        e%end_time = t + interval
        e%count = 1
        limited = .false.
    end function rate_limit

end module rate_limiter


program main
    use rate_limiter
    use sleep_mod
    implicit none

    character(len=32) :: arg
    logical :: test_mode

    test_mode = .false.
    if (command_argument_count() == 1) then
        call get_command_argument(1, arg)
        test_mode = (trim(arg) == 'test')
    end if

    if (test_mode) then
        call exercise_rate_limiter('216.239.34.21:/api/v1/payroll_report', 5, 2, 120)
        write (*, '(A)') ''
    else
        block
            character(len=*), parameter :: key = '192.168.4.127:/api/v1/users'

            ! false
            call print_bool(rate_limit(key, 5, 3))
            call print_bool(rate_limit(key, 5, 3))
            call print_bool(rate_limit(key, 5, 3))

            ! true
            call print_bool(rate_limit(key, 5, 3))
        end block
    end if

contains

    subroutine print_bool(value)
        logical, intent(in) :: value
        if (value) then
            write (*, '(A)') 'true'
        else
            write (*, '(A)') 'false'
        end if
    end subroutine print_bool

    ! Drives the limiter through `windows` full windows, printing a dot for
    ! each allowed request and a newline each time the limit is hit.
    subroutine exercise_rate_limiter(key, windows, interval, max_count)
        character(*), intent(in) :: key
        integer, intent(in) :: windows, interval, max_count
        integer :: i

        do i = 1, windows
            do
                if (.not. rate_limit(key, interval, max_count)) then
                    ! Not rate limited.
                    write (*, '(A)', advance='no') '.'
                    flush (6)
                    cycle
                end if

                ! Rate limited: end this window's output and, unless this was
                ! the last window, poll until the next window opens.
                write (*, '(A)') ''
                if (i < windows) then
                    do
                        call sleep_ms(10)
                        if (.not. rate_limit(key, interval, max_count)) then
                            write (*, '(A)', advance='no') '.'
                            flush (6)
                            exit
                        end if
                    end do
                end if
                exit
            end do
        end do
    end subroutine exercise_rate_limiter

end program main
