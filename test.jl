const jobs = Channel{Int}(32);
const results = Channel{Tuple}(32);
function do_work()
    for job_id in jobs
        exec_time = rand()
        sleep(exec_time)                # simulates elapsed time doing actual work
                                        # typically performed externally.
        put!(results, (job_id, exec_time))
    end
end;
function make_jobs(n)
    for i in 1:n
        put!(jobs, i)
    end
end;