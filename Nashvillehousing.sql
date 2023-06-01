 -- Load in data that will be used
 
 LOAD DATA LOCAL INFILE '/Users/adrayningram/Downloads/Nashville Housing Data for Data Cleaning.csv'
	INTO TABLE DataCleaning.nashvillehousing 
    FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        IGNORE 1 LINES;

SELECT * 
FROM DataCleaning.nashvillehousing;

-- Convert Date Formating

SELECT SaleDateConverted , CONVERT(SaleDate, DATE)
FROM DataCleaning.nashvillehousing;

-- (Update not registering) Work around used
UPDATE DataCleaning.nashvillehousing
SET SaleDate = CONVERT(SaleDate, DATE);

ALTER TABLE DataCleaning.nashvillehousing
ADD SaleDateConverted DATE;

UPDATE DataCleaning.nashvillehousing
SET SaleDateConverted = CONVERT(SaleDate, DATE);

-- Populate Poperty Address using matching Parcel ID

SELECT *
FROM DataCleaning.nashvillehousing
WHERE PropertyAddress IS NULL;

SELECT *
FROM DataCleaning.nashvillehousing
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, COALESCE(a.PropertyAddress, b.PropertyAddress) AS CorrectedAddress
FROM DataCleaning.nashvillehousing a
JOIN DataCleaning.nashvillehousing b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID  <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

UPDATE DataCleaning.nashvillehousing a
JOIN (
    SELECT a.ParcelID, COALESCE(a.PropertyAddress, b.PropertyAddress) AS CorrectedAddress
    FROM DataCleaning.nashvillehousing a
    JOIN DataCleaning.nashvillehousing b
        ON a.ParcelID = b.ParcelID
        AND a.UniqueID <> b.UniqueID
    WHERE a.PropertyAddress IS NULL
) AS subquery
ON a.ParcelID = subquery.ParcelID
SET a.PropertyAddress = subquery.CorrectedAddress;

-- Seperating Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM DataCleaning.nashvillehousing;

SELECT
SUBSTRING(PropertyAddress, 1, LOCATE(',',PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, LOCATE(',',PropertyAddress) +1, CHAR_LENGTH(PropertyAddress)) as City
FROM DataCleaning.nashvillehousing;

ALTER TABLE DataCleaning.nashvillehousing
ADD PropertySplitAddress CHAR(255);

UPDATE DataCleaning.nashvillehousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, LOCATE(',',PropertyAddress) -1);

ALTER TABLE DataCleaning.nashvillehousing
ADD PropertySplitCity CHAR(255);

UPDATE DataCleaning.nashvillehousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, LOCATE(',',PropertyAddress) +1, CHAR_LENGTH(PropertyAddress));

SELECT OwnerAddress
FROM DataCleaning.nashvillehousing;

SELECT 
SUBSTRING_INDEX(OwnerAddress,',', 1) AS OwnerAddressCorrected,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1) AS OwnerCity,
SUBSTRING_INDEX(OwnerAddress,',', -1) AS OwnerState
FROM DataCleaning.nashvillehousing;

ALTER TABLE DataCleaning.nashvillehousing
ADD OwnerAddressCorrected CHAR(255);

UPDATE DataCleaning.nashvillehousing
SET OwnerAddressCorrected = SUBSTRING_INDEX(OwnerAddress,',', 1);

ALTER TABLE DataCleaning.nashvillehousing
ADD OwnerCity CHAR(255);

UPDATE DataCleaning.nashvillehousing
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1);

ALTER TABLE DataCleaning.nashvillehousing
ADD OwnerState CHAR(255);

UPDATE DataCleaning.nashvillehousing
SET OwnerState = SUBSTRING_INDEX(OwnerAddress,',', -1);

-- Change SoldAsVacant to Only Yes and No

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM DataCleaning.nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM DataCleaning.nashvillehousing;

UPDATE DataCleaning.nashvillehousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END;

-- Removing duplicates using Subquery

WITH RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
    PARTITION BY ParcelID,
				PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
			ORDER BY 
				UniqueID
		)row_num
FROM DataCleaning.nashvillehousing
)
SELECT * 
FROM RowNumCTE
-- ORDER BY ParcelID
WHERE row_num > 1;

DELETE FROM DataCleaning.nashvillehousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID, ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
        FROM DataCleaning.nashvillehousing
    ) AS RowNumCTE
    WHERE row_num > 1
);

-- Delete Unused Columns

SELECT * 
FROM DataCleaning.nashvillehousing;

ALTER TABLE DataCleaning.nashvillehousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict,
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;
