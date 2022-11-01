#the number of jobs reviewed per hour per day for November 2020
select 
count(job_id)/(30*24) as num_jobs_reviewed
from job_data
where 
ds between "2020-11-01" and "2020-11-30";
#7 day rolling average of throughput
#throughtput - calcualting rolling average
select ds,
  jobs_reviewed,
  avg(jobs_reviewed)over(order by ds rows between 6 preceding and current row) as rolling_average
  from
(
select ds,
count(distinct job_id) as jobs_reviewed
from
job_data
where ds between "2020-11-01" and "2020-11-30"
group by ds
order by ds
)a;

#the percentage share of each language in the last 30 days.
select language,
num_jobs,
100*(num_jobs/total_jobs) as pct_share
from
(select 
ds,
language,
count(job_id) as num_jobs
from job_data
group by language)a
cross join(select count(job_id) as total_jobs from job_data)b;

# displaying duplicate rows
select * from(select *,row_number()over(partition by job_id) as rownum from job_data)a where rownum>1;

#the weekly user engagement
select extract(week from occurred_at) as weeknum,count(distinct user_id) from events
group by weeknum;

#the user growth for product
select year,weeknum,num_active_user,sum(num_active_user) over(order by year,weeknum rows between unbounded preceding and current row) as cum_active_users
from(select extract(year from activated_at) as year,extract(week from activated_at)as weeknum,count(distinct user_id) as num_active_user
from opusers a where state="active" group by year,weeknum order by year,weeknum)a;

#the weekly retention of users-sign up cohort.
select extract(year from occurred_at)as year,
extract(week from occurred_at)as week,
device,
count(distinct user_id)
from events 
where event_type="engagement" 
group by 1,2,3 
order by 1,2,3;

#email engagement metrics
SELECT COUNT(user_id), SUM(CASE WHEN retention_week = 1 THEN 1 ELSE 0 END) as week_1 
FROM ( SELECT a.user_id, a.signup_week, b.engagement_week, b.engagement_week - a.signup_week AS retention_week 
FROM ( (SELECT DISTINCT user_id, EXTRACT(week FROM occurred_at) AS signup_week 
FROM events WHERE event_type = 'signup_flow' AND event_name = 'complete_signup' AND EXTRACT(week from occurred_at) = 18 ) a 
LEFT JOIN ( SELECT DISTINCT user_id, EXTRACT(week FROM occurred_at) AS engagement_week from events WHERE event_type = 'engagement' ) b ON a.user_id = b.user_id ) 
ORDER BY a.user_id )a
