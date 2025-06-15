/*The database consists of tables that store information about book titles, authors, publishers, publication years, user ratings, and user details*/

SELECT * 
FROM Book_recommendation_db..Books; 

SELECT * 
FROM Book_recommendation_db..Ratings;

SELECT * 
FROM Book_recommendation_db..Users;

--Before performing any queries or analysis, the raw data is being cleaned to handle missing values, remove duplicates, and correct inconsistencies.

--Some columns in the book table contain null values.

SELECT *
FROM 
    Book_recommendation_db..Books
WHERE 
    [Year-Of-Publication] IS NULL; 

/*The previous query identified NULL value in the 'Year_of_publication' column. 
Some of these rows also have missing book titles.
The following query removes rows where the 'Year_of_publication' is NULL and the book title is also missing."
*/

DELETE from Book_recommendation_db..Books
WHERE 
    [Year-Of-Publication] IS NULL;


--Updating rows of 'Year of publication' column which has ISBN no.

UPDATE Book_recommendation_db..Books
SET [Year-Of-Publication] = '1943'
WHERE ISBN = '140201092';

UPDATE Book_recommendation_db..Books
SET [Year-Of-Publication] = CASE ISBN 
    WHEN '671746103'  THEN '1996'
	WHEN '870446924'  THEN '1999'
	WHEN '671266500' THEN '1961'
	WHEN '671791990' THEN '1997'
	WHEN '394701658' THEN '1959'
    WHEN '3442436893' THEN '2006'
    WHEN '684718022' THEN '1925'
    WHEN '870449842' THEN '1979'
    WHEN '140301690' THEN '1871'
	ELSE '0'
END
WHERE ISBN IN ('671746103', '870446924', '671266500', '671791990','394701658', '3442436893','84718022','870449842','140301690');

UPDATE Book_recommendation_db..Books
SET [Year-Of-Publication] = '1991'
WHERE ISBN = '671740989';


--Check for NULL values in the 'Book-Author' column 

SELECT *
FROM Book_recommendation_db..Books
WHERE [Book-Author] IS NULL;

/* Only one NULL value was found in the 'Book-Author' column. 
Update it with the correct author name.*/

UPDATE Book_recommendation_db..Books
SET [Book-Author]= 'Larissa Anne Downes'
WHERE ISBN = 9627982032;


--Add a new column 'Age_groups' to the Users table to categorize user ages 

ALTER TABLE Book_recommendation_db..Users
ADD Age_groups VARCHAR(10) NOT NULL;

--Populate 'Age_groups' column by grouping ages into ranges.

UPDATE Book_recommendation_db..Users
SET Age_groups = CASE
    WHEN Age BETWEEN 0 AND 20 THEN '16 - 20'
	WHEN Age BETWEEN 21 AND 30 THEN '21 - 30'
	WHEN Age BETWEEN 31 AND 40 THEN '31 - 40'
	WHEN Age BETWEEN 41 AND 50 THEN '41 - 50'
	WHEN Age BETWEEN 51 AND 55 THEN '51 - 55'
	WHEN Age > 55 THEN '55+'
	WHEN AGE IS NULL THEN 'Unknown'
	ELSE '0'
END;

--Check for NULL values in the 'Publisher' column

SELECT Publisher
FROM Book_recommendation_db..Books
WHERE Publisher IS NULL;

-- Fill missing Publisher values for specific books/authors

UPDATE Book_recommendation_db..Books
SET Publisher = 'NovelBooks'
WHERE [Book-Author] = 'Linnea Sinclair';

UPDATE Book_recommendation_db..Books
SET Publisher = 'NovelBooks'
WHERE [Book-Title] = 'Tyrant Moon';


-- Add a new column 'Country' to the Users table */
ALTER TABLE Book_recommendation_db..Users
ADD Country varchar(50)

--Populate the 'Country' column by extracting the last part of the 'Location' field.

UPDATE Book_recommendation_db..Users
SET Country = PARSENAME(REPLACE(Location,',','.'),1)

----------------

--- Pre-joining the table of books and ratings 

CREATE VIEW book_rating_view AS
SELECT 
    b.ISBN AS book_ISBN,
	b.[Book-Title],
	b.[Book-Author],
	b.[Year-Of-Publication],
	b.Publisher, 
	r.ISBN,
	r.[User-ID],
	r.[Book-Rating]
FROM Book_recommendation_db..Books AS b
JOIN
    Book_recommendation_db..Ratings AS r
    ON b.ISBN = r.ISBN
;

-------------------
---- Data overview
-- Total number of books
SELECT
    COUNT(DISTINCT(ISBN)) AS Total_books
FROM Book_recommendation_db..Books;

-- Total number of users
SELECT
    COUNT(DISTINCT([User-ID])) AS Total_users
FROM Book_recommendation_db..Users;


----- Book Trends
-- 1. Top rated books across all years
SELECT 
    v.[Book-Title], 
	MAX(v.[Book-Rating]) AS Ratings,
	v.[Year-Of-Publication]
FROM 
    book_rating_view AS v
GROUP BY 
    v.[Year-Of-Publication], 
	v.[Book-Title]
Having 
    MAX(V.[Book-Rating]) > 7
ORDER BY 
    [Book-Title], 
	Ratings DESC;

-- 2. Most reviewed books
SELECT 
    v.[Book-Title], 
	COUNT(*) AS total_reviews
FROM 
    book_rating_view AS v
GROUP BY 
    v.[Book-Title]
ORDER BY 
    total_reviews DESC;

-- 3. Hidden gems (Highly rated but less reviewed books)
SELECT 
    v.[Book-Title], 
	COUNT(v.[Book-Rating]) AS total_rating, 
	AVG(v.[Book-Rating]) AS avg_rating
FROM 
    book_rating_view AS v
GROUP BY 
    v.[Book-Title]
HAVING 
    COUNT(v.[Book-Rating]) BETWEEN 10 AND 50
	AND AVG(v.[Book-Rating]) >=7
ORDER BY 
    total_rating;


----- Author & Publisher Influence
-- 4. count of book published every year
SELECT 
    [Year-Of-Publication], 
	COUNT(*) AS book_count
FROM 
    Book_recommendation_db..Books
GROUP BY 
    [Year-Of-Publication]
ORDER BY 
    [Year-Of-Publication]; 

-- 5. Authors who have written the most number of books
SELECT 
    [Book-Author], 
	COUNT(*) AS total_books
FROM 
    Book_recommendation_db..Books
GROUP BY 
    [Book-Author]
ORDER BY 
    total_books DESC;

-- 6. Which publishers have the largest catalog?
SELECT 
    Publisher, 
	COUNT(*) as published_books 
FROM 
    Book_recommendation_db..Books
GROUP BY 
    Publisher
ORDER BY
    published_books DESC;

-- 7. Regional popularity of authors
WITH Regional_popularity AS(
    SELECT 
        b.[Book-Author], 
		u.Country, 
        COUNT(b.[Book-Author]) AS popularity_count
    FROM 
        Book_recommendation_db..Books AS b
    JOIN  
        Book_recommendation_db..Ratings AS r
        ON b.ISBN = r.ISBN
    JOIN  
        Book_recommendation_db..Users AS u
        ON r.[User-ID] = u.[User-ID]
    GROUP BY 
        u.Country, b.[Book-Author]
)	
SELECT *
FROM Regional_popularity
ORDER BY popularity_count DESC;


---- Rating analysis
-- 8. Average rating per book
SELECT 
    v.[Book-Title], 
	COUNT(v.[Book-Rating]) AS Total_ratings, 
	AVG(v.[Book-Rating]) AS Avg_rating
FROM 
    book_rating_view AS v
WHERE 
    v.[Book-Rating] > 0 
GROUP BY 
    [Book-Title]
ORDER BY  
    Total_ratings DESC;

-- 9. Book with low rating 
SELECT
    v.[Book-Title],
	v.[Book-Rating], 
	COUNT(v.[User-ID]) AS user_count
FROM 
    book_rating_view AS v
WHERE 
    v.[Book-Rating] < 4
GROUP BY 
    v.[Book-Title], v.[Book-Rating]
ORDER BY 
    user_count DESC;

-- 10. Book rating distribution
SELECT 
    [Book-Rating], COUNT(*) AS Total_ratings
FROM 
    Book_recommendation_db..Ratings
GROUP BY 
    [Book-Rating]
ORDER BY 
    [Book-Rating];

-- 11. Publish year vs ratings (Are older books rated higher than newer ones? )
SELECT 
    COUNT(v.[Book-Rating]) AS rating, 
	v.[Year-Of-Publication]
FROM 
    book_rating_view AS v
WHERE 
    v.[Book-Rating] > 4
GROUP BY 
    v.[Year-Of-Publication]
ORDER BY 
    v.[Year-Of-Publication];


----- User Demographics
-- 12. Total number of active users who rated books
SELECT 
    users.Country, 
	count(DISTINCT(users.[User-ID])) AS user_count
FROM 
    Book_recommendation_db..Users AS users
JOIN 
    Book_recommendation_db..Ratings AS rating
    ON users.[User-ID] = rating.[User-ID]
WHERE 
    rating.[Book-Rating] != '0'   
GROUP BY  
    users.Country, 
	rating.[Book-Rating]
ORDER BY 
    user_count DESC;

-- 13. Countries have the most active users
SELECT 
    Country, 
	COUNT([User-ID]) AS active_users
FROM 
    Book_recommendation_db..Users AS U
GROUP BY 
    Country
ORDER BY 
    active_users DESC;

-- 14. Total User Count by Age Group
SELECT 
    Age_groups, 
	COUNT(*) AS total_users
FROM 
    Book_recommendation_db..Users AS u
GROUP BY 
    u.Age_groups;

-- 15. Age group behavior in book rating
SELECT
    u.Age_groups,
	r.[Book-Rating],
	COUNT(r.[Book-Rating]) AS total_ratings
FROM 
    Book_recommendation_db..Users AS u
JOIN 
    Book_recommendation_db..Ratings AS r
    ON u.[User-ID] = r.[User-ID]
GROUP BY
    u.Age_groups, 
	r.[Book-Rating]
ORDER BY
    u.Age_groups, 
	r.[Book-Rating];
