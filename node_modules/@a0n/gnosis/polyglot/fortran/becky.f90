! becky.f90 -- GG compiler in Fortran.
! The oldest compiled language in the race. Fixed-size arrays. No hash map.
! Build: gfortran -O3 -o becky-fortran becky.f90
! Usage: ./becky-fortran betti.gg --summary

program becky
    implicit none
    character(len=65536) :: source, cleaned
    character(len=256) :: filepath, arg
    character(len=128) :: node_ids(512)
    character(len=32)  :: edge_types(256)
    integer :: edge_src_count(256), edge_tgt_count(256)
    integer :: node_count, edge_count, beta1
    integer :: i, argc, bench_iters, void_dims
    logical :: beta1_only, summary_mode
    real(8) :: start_time, end_time, us_per_iter, heat
    integer :: source_len, cleaned_len

    node_count = 0
    edge_count = 0
    beta1 = 0
    bench_iters = 0
    beta1_only = .false.
    summary_mode = .false.
    filepath = ''

    ! Parse CLI args
    argc = command_argument_count()
    i = 1
    do while (i <= argc)
        call get_command_argument(i, arg)
        if (arg == '--beta1') then
            beta1_only = .true.
        else if (arg == '--summary') then
            summary_mode = .true.
        else if (arg == '--bench') then
            i = i + 1
            call get_command_argument(i, arg)
            read(arg, *) bench_iters
        else
            filepath = trim(arg)
        end if
        i = i + 1
    end do

    if (len_trim(filepath) == 0) then
        write(0, '(A)') 'usage: becky-fortran [--beta1|--summary|--bench N] <file.gg>'
        stop 1
    end if

    ! Read file
    call read_file(filepath, source, source_len)
    if (source_len == 0) then
        write(0, '(A,A)') 'becky-fortran: cannot read ', trim(filepath)
        stop 1
    end if

    ! Strip comments and parse
    call strip_comments(source, source_len, cleaned, cleaned_len)

    if (bench_iters > 0) then
        ! Warmup
        do i = 1, 10
            node_count = 0; edge_count = 0
            call parse_gg(cleaned, cleaned_len, node_ids, node_count, &
                         edge_types, edge_src_count, edge_tgt_count, edge_count)
        end do
        call cpu_time(start_time)
        do i = 1, bench_iters
            node_count = 0; edge_count = 0
            call parse_gg(cleaned, cleaned_len, node_ids, node_count, &
                         edge_types, edge_src_count, edge_tgt_count, edge_count)
        end do
        call cpu_time(end_time)
        us_per_iter = (end_time - start_time) * 1.0d6 / bench_iters

        beta1 = compute_beta1(edge_types, edge_src_count, edge_tgt_count, edge_count)
        void_dims = compute_void(edge_types, edge_tgt_count, edge_count)
        heat = compute_heat(edge_types, edge_src_count, edge_count)

        write(*, '(F8.1,A,I0,A,I0,A,I0,A,I0,A,I0,A,F6.3)') &
            us_per_iter, 'us/iter | ', bench_iters, ' iterations | ', &
            node_count, ' nodes ', edge_count, ' edges | b1=', beta1, &
            ' | void=', void_dims, ' heat=', heat
        stop
    end if

    call parse_gg(cleaned, cleaned_len, node_ids, node_count, &
                 edge_types, edge_src_count, edge_tgt_count, edge_count)
    beta1 = compute_beta1(edge_types, edge_src_count, edge_tgt_count, edge_count)
    void_dims = compute_void(edge_types, edge_tgt_count, edge_count)
    heat = compute_heat(edge_types, edge_src_count, edge_count)

    if (beta1_only) then
        write(*, '(I0)') beta1
    else if (summary_mode) then
        write(*, '(A,A,I0,A,I0,A,I0,A,I0,A,F6.3)') &
            trim(filepath), ': ', node_count, ' nodes, ', edge_count, &
            ' edges, b1=', beta1, ', void=', void_dims, ', heat=', heat
    else
        write(*, '(A,I0,A,I0,A,I0,A)') &
            '{"nodes":', node_count, ',"edges":', edge_count, ',"beta1":', beta1, '}'
    end if

contains

    subroutine read_file(path, buf, buflen)
        character(len=*), intent(in) :: path
        character(len=*), intent(out) :: buf
        integer, intent(out) :: buflen
        integer :: u, ios
        character(len=256) :: line

        buf = ''
        buflen = 0
        open(newunit=u, file=trim(path), status='old', iostat=ios)
        if (ios /= 0) return
        do
            read(u, '(A)', iostat=ios) line
            if (ios /= 0) exit
            if (buflen + len_trim(line) + 1 < len(buf)) then
                buf(buflen+1:buflen+len_trim(line)) = trim(line)
                buflen = buflen + len_trim(line)
                buf(buflen+1:buflen+1) = char(10) ! newline
                buflen = buflen + 1
            end if
        end do
        close(u)
    end subroutine

    subroutine strip_comments(src, srclen, dst, dstlen)
        character(len=*), intent(in) :: src
        integer, intent(in) :: srclen
        character(len=*), intent(out) :: dst
        integer, intent(out) :: dstlen
        integer :: i, line_start, line_end, comment_pos
        logical :: in_content

        dst = ''
        dstlen = 0
        line_start = 1

        do i = 1, srclen + 1
            if (i > srclen .or. src(i:i) == char(10)) then
                line_end = i - 1
                ! Find // comment
                comment_pos = index(src(line_start:line_end), '//')
                if (comment_pos > 0) then
                    line_end = line_start + comment_pos - 2
                end if
                ! Trim and copy if non-empty
                in_content = .false.
                do while (line_start <= line_end .and. src(line_start:line_start) == ' ')
                    line_start = line_start + 1
                end do
                do while (line_end >= line_start .and. src(line_end:line_end) == ' ')
                    line_end = line_end - 1
                end do
                if (line_end >= line_start) then
                    dst(dstlen+1:dstlen+(line_end-line_start+1)) = src(line_start:line_end)
                    dstlen = dstlen + (line_end - line_start + 1)
                    dst(dstlen+1:dstlen+1) = char(10)
                    dstlen = dstlen + 1
                end if
                line_start = i + 1
            end if
        end do
    end subroutine

    subroutine parse_gg(src, srclen, nodes, ncount, etypes, esrc, etgt, ecount)
        character(len=*), intent(in) :: src
        integer, intent(in) :: srclen
        character(len=128), intent(inout) :: nodes(512)
        integer, intent(inout) :: ncount
        character(len=32), intent(inout) :: etypes(256)
        integer, intent(inout) :: esrc(256), etgt(256)
        integer, intent(inout) :: ecount
        integer :: i, j, paren_start, bracket_start, bracket_end
        integer :: arrow_pos, tgt_start, tgt_end, depth
        character(len=256) :: src_raw, tgt_raw, etype

        ! Sweep for edges: find )-[:
        i = 1
        do while (i + 3 <= srclen)
            if (src(i:i+3) == ')-[:') then
                ! Backtrack for source (
                paren_start = i
                depth = 0
                do j = i-1, 1, -1
                    if (src(j:j) == ')') depth = depth + 1
                    if (src(j:j) == '(') then
                        if (depth == 0) then
                            paren_start = j + 1
                            exit
                        end if
                        depth = depth - 1
                    end if
                end do
                src_raw = src(paren_start:i-1)

                ! Find ]
                bracket_start = i + 4
                bracket_end = index(src(bracket_start:srclen), ']')
                if (bracket_end > 0) then
                    bracket_end = bracket_start + bracket_end - 2
                    ! Extract type (before { or end)
                    etype = src(bracket_start:bracket_end)
                    j = index(etype, '{')
                    if (j > 0) etype = etype(1:j-1)
                    etype = adjustl(etype)

                    ! Find ->
                    arrow_pos = bracket_start + (bracket_end - bracket_start + 1) + 1
                    if (arrow_pos + 1 <= srclen .and. src(arrow_pos:arrow_pos+1) == '->') then
                        ! Find target (...)
                        tgt_start = index(src(arrow_pos+2:srclen), '(')
                        if (tgt_start > 0) then
                            tgt_start = arrow_pos + 2 + tgt_start
                            depth = 1
                            tgt_end = tgt_start
                            do j = tgt_start, srclen
                                if (src(j:j) == '(') depth = depth + 1
                                if (src(j:j) == ')') then
                                    depth = depth - 1
                                    if (depth == 0) then
                                        tgt_end = j - 1
                                        exit
                                    end if
                                end if
                            end do
                            tgt_raw = src(tgt_start:tgt_end)

                            ! Count sources and targets (by |)
                            if (ecount < 256) then
                                ecount = ecount + 1
                                etypes(ecount) = trim(etype)
                                esrc(ecount) = count_pipe(src_raw) + 1
                                etgt(ecount) = count_pipe(tgt_raw) + 1
                            end if

                            ! Add nodes
                            call add_pipe_nodes(src_raw, nodes, ncount)
                            call add_pipe_nodes(tgt_raw, nodes, ncount)

                            i = tgt_end + 2
                            cycle
                        end if
                    end if
                end if
            end if
            i = i + 1
        end do
    end subroutine

    function count_pipe(raw) result(n)
        character(len=*), intent(in) :: raw
        integer :: n, i
        n = 0
        do i = 1, len_trim(raw)
            if (raw(i:i) == '|') n = n + 1
        end do
    end function

    subroutine add_pipe_nodes(raw, nodes, ncount)
        character(len=*), intent(in) :: raw
        character(len=128), intent(inout) :: nodes(512)
        integer, intent(inout) :: ncount
        integer :: i, start
        character(len=128) :: id

        start = 1
        do i = 1, len_trim(raw) + 1
            if (i > len_trim(raw) .or. raw(i:i) == '|') then
                id = raw(start:i-1)
                call extract_id(id)
                if (len_trim(id) > 0) call ensure_node(id, nodes, ncount)
                start = i + 1
            end if
        end do
    end subroutine

    subroutine extract_id(s)
        character(len=*), intent(inout) :: s
        integer :: i
        s = adjustl(s)
        ! Remove parens
        if (s(1:1) == '(') s = s(2:)
        i = len_trim(s)
        if (i > 0 .and. s(i:i) == ')') s(i:i) = ' '
        ! Take before : or {
        i = index(s, ':')
        if (i > 0) s = s(1:i-1)
        i = index(s, '{')
        if (i > 0) s = s(1:i-1)
        s = adjustl(s)
        ! Trim trailing spaces
        s = trim(s)
    end subroutine

    subroutine ensure_node(id, nodes, ncount)
        character(len=*), intent(in) :: id
        character(len=128), intent(inout) :: nodes(512)
        integer, intent(inout) :: ncount
        integer :: i
        do i = 1, ncount
            if (trim(nodes(i)) == trim(id)) return
        end do
        if (ncount < 512) then
            ncount = ncount + 1
            nodes(ncount) = trim(id)
        end if
    end subroutine

    function compute_beta1(etypes, esrc, etgt, ecount) result(b1)
        character(len=32), intent(in) :: etypes(256)
        integer, intent(in) :: esrc(256), etgt(256), ecount
        integer :: b1, i
        b1 = 0
        do i = 1, ecount
            select case (trim(etypes(i)))
            case ('FORK'); b1 = b1 + etgt(i) - 1
            case ('FOLD', 'COLLAPSE', 'OBSERVE'); b1 = max(0, b1 - (esrc(i) - 1))
            case ('RACE', 'SLIVER'); b1 = max(0, b1 - max(0, esrc(i) - etgt(i)))
            case ('VENT'); b1 = max(0, b1 - 1)
            end select
        end do
    end function

    function compute_void(etypes, etgt, ecount) result(d)
        character(len=32), intent(in) :: etypes(256)
        integer, intent(in) :: etgt(256), ecount
        integer :: d, i
        d = 0
        do i = 1, ecount
            if (trim(etypes(i)) == 'FORK') d = d + etgt(i)
        end do
    end function

    function compute_heat(etypes, esrc, ecount) result(h)
        character(len=32), intent(in) :: etypes(256)
        integer, intent(in) :: esrc(256), ecount
        real(8) :: h
        integer :: i
        h = 0.0d0
        do i = 1, ecount
            if ((trim(etypes(i)) == 'FOLD' .or. trim(etypes(i)) == 'COLLAPSE' &
                .or. trim(etypes(i)) == 'OBSERVE') .and. esrc(i) > 1) then
                h = h + log(dble(esrc(i))) / log(2.0d0)
            end if
        end do
    end function

end program
