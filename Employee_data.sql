CREATE TABLE employee_demographics(
	employee_id INT,
    first_name TEXT,
    last_name TEXT,
    age INT);

CREATE TABLE employee_salary_set(
	emp_id INT,
    first_name TEXT,
    last_name TEXT,
    salary INT);
    
    
INSERT INTO employee_demographics(employee_id,first_name,last_name,age)
VALUES(1,'kurk','R',22),
(2,'mark','L',19),
(3,'james','D',55),
(4,'jacob','F',44),
(5,'hunter','F',38),
(6,'frank','P',33),
(7,'bill','T',23),
(8,'hannah','S',19),
(9,'taylor','Y',67),
(10,'jim','A',43),
(11,'kyle','L',35);

INSERT INTO employee_salary_set(emp_id,first_name,last_name,salary)
VALUES(1,'kurk','R',35000),
(2,'mark','L',87000),
(3,'james','D',55000),
(4,'jacob','F',45000),
(5,'hunter','F',50000),
(6,'frank','P',35000),
(7,'bill','T',60000),
(8,'hannah','S',100000),
(9,'taylor','Y',65000),
(10,'jim','A',45000),
(11,'kyle','L',80000);

SELECT * FROM employee_demographics;
SELECT * FROM employee_salary_set;

INSERT INTO employee_demographics(employee_id,first_name,last_name,age,birthday)
VALUES(12,'jason','lamb',110,'10-15-1903');

#add column with new gender values
ALTER TABLE employee_demographics
ADD gender TEXT;

SET SQL_SAFE_UPDATES = 0;

UPDATE employee_demographics
SET gender = 'male' 
WHERE gender IS NULL;

UPDATE employee_demographics
SET gender = 'female' 
WHERE first_name = 'hannah';

UPDATE employee_demographics
SET gender = 'female' 
WHERE first_name = 'taylor';

UPDATE employee_demographics
SET gender = 'female' 
WHERE first_name = 'james';

#It's coming up to the holiday season, and our workplace wants to do a secret santa!
#Lets use a self join on our table to give everyone a perfect match as a partner!

SELECT emp1.employee_id,emp1.first_name AS Secret_santa,
emp2.employee_id,emp2.first_name AS Gift_Reciever
FROM employee_demographics AS emp1
JOIN employee_demographics AS emp2
	ON emp1.employee_id  + 1 = emp2.employee_id;
    
#Our name values are the same in both tables, so if we perform a simple Union 
#between the two with our names, we'll only get back one set of first name's
#this is because unions only return distinct values, if we want to recieve 
#all values even if theyre duplicate, we can use "all"

SELECT first_name
FROM employee_demographics
UNION ALL
SELECT first_name
FROM employee_salary_set;


#using multiple unions, I want to filter through both tables to visualize who is getting paid
#over our new pay limit of 80,000 just established by HR. We also want to identify if the 
#employees that are getting overpaid are younger or older at our company.

SELECT first_name, last_name, 'overpaid' AS label
FROM employee_salary_set
WHERE salary > 80000
UNION 
SELECT first_name, last_name, 'Younger' AS label
FROM employee_demographics
WHERE age < 49
UNION
SELECT first_name, last_name, 'Older' AS label
FROM employee_demographics
WHERE age > 50
ORDER BY first_name, last_name;


#Now I want to compare everyones salary to the average salary for gender to see 
#if I can determine any signficant pay gaps. The best way to do this is 
#by partitioning over the average salary for the gender, and comparing 
#our person and their salary that corresponds to that average salary.

SELECT dem.first_name,gender, salary,
AVG(salary) OVER(PARTITION BY gender) AS avg_sal_for_gender
FROM employee_demographics AS dem
JOIN employee_salary_set AS sal
	ON dem.employee_id = sal.emp_id;

#we could also do this with the Max salary, and visualize the difference 
#between giving a unique row_number and ranking. Here i'll visualize the salary 
#of each person in my table and comapre it to their max value

#(Notice how the ranking and the row_number restarts as the partitioned gender 
#switched from female to male, but when a similar salary if found between 
#kurk and frank, the ranking number is the same while the row_number is not affected.

SELECT dem.first_name,dem.last_name,salary, 
MAX(salary) OVER(PARTITION BY gender) AS max_gender_sal,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_desc,
RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS ranking
FROM employee_demographics as dem
JOIN employee_salary_set AS sal
	ON dem.employee_id = sal.emp_id;
    
#Now I want to utilize a rolling total, a feature I can build which can provide use in understanding 
#at each step how we reached a total amount

SELECT dem.first_name, dem.last_name,salary, SUM(salary) OVER(ORDER BY dem.employee_id) AS rolling_total
FROM employee_demographics AS dem
JOIN employee_salary_set AS sal
	ON dem.employee_id = sal.emp_id;
   
    
#what is the output difference if we Order by gender VS partition by gender? What differences
#can we visualize

SELECT dem.first_name, dem.last_name,salary, SUM(salary) OVER(ORDER BY gender) AS rolling_total_ordered_by_gender
FROM employee_demographics AS dem
JOIN employee_salary_set AS sal
	ON dem.employee_id = sal.emp_id;
#all this does is gives us the sum of female salaries and then adds that to the sum of male salaries
#but does not give us useful insight into each step.

SELECT dem.first_name, dem.last_name,salary, SUM(salary) OVER(PARTITION BY gender) AS sum_for_gender
FROM employee_demographics AS dem
JOIN employee_salary_set AS sal
	ON dem.employee_id = sal.emp_id;
    
#when we partition by gender, we are getting a visual of the sum for each gender, here we have a seperated total for females
#and a seperated sum for men because were partioning by gender, we are NOT adding females SUM to Mens SUM
#like a rolling total would do.


#Lets get the average salary by age and see how the average salary changes as other
#employees salaries are added in to give us a final average salary.

SELECT dem.first_name, dem.last_name, dem.age,salary,
AVG(salary) OVER(ORDER BY age) AS avg_sal_by_age,
ROW_NUMBER() OVER(ORDER BY age) AS row_num
FROM employee_demographics AS dem
JOIN employee_salary_set AS sal
ON dem.employee_id = sal.emp_id;


SELECT * FROM employee_demographics;
SELECT * FROM employee_salary_set;


SELECT AVG(max_sal)
FROM(
	SELECT salary,
    AVG(salary) AS avg_sal, 
	MAX(salary) AS max_sal, 
	COUNT(salary) AS count_sal
    FROM employee_salary_set
    GROUP BY salary) 
as agg_table;
# If i want to perform a double aggregate, a subquery in a from statement that 
#retrieves the average max salary does this easily for me.


#select everything from salary set, where the first name in the salary set
#matches the first name in the demographic set where the age is greater than 30
#this is useful for finding more detailed insights across multiple tables with 
#similar data

SELECT *
FROM employee_salary_set
WHERE first_name IN(
	SELECT first_name
    FROM employee_demographics
    WHERE age > 30); 

SELECT employee_id,first_name
FROM employee_demographics
WHERE first_name IN(
	SELECT first_name
    FROM employee_salary_set
    WHERE salary > 70000);
    
#give us the employee's id and first name from our demographic set 
#where the first name in our demographics matches the first name in salary_set
# where the salary is greater than 70k

#Heres a creative way to derive data from another table using a select statement 
#within a select statement without having to perform a join
SELECT employee_id,first_name,age,(
	SELECT AVG(salary)
    FROM employee_salary_set) AS avg_sal
    FROM employee_demographics;
    

#This concludes our data analysis into our two sets of tables from our company.
