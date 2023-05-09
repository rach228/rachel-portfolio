
SELECT *
FROM projects.nashvillehousing2;


-- Standardize date format

SELECT SaleDate, STR_TO_DATE(SaleDate, '%m/%d/%y')
FROM projects.nashvillehousing2;

ALTER TABLE projects.nashvillehousing2
ADD COLUMN SaleDateConverted DATE AFTER SaleDate;

UPDATE projects.nashvillehousing2
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%m/%d/%y');

-------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM projects.nashvillehousing2
-- WHERE PropertyAddress = '';
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IF(a.PropertyAddress = '', b.PropertyAddress, b.PropertyAddress)
FROM projects.nashvillehousing2 a
JOIN projects.nashvillehousing2 b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress = '';

UPDATE projects.nashvillehousing2 a
JOIN projects.nashvillehousing2 b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IF(a.PropertyAddress = '', b.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress = '';

-------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

-- PropertyAddress
SELECT PropertyAddress
FROM projects.nashvillehousing2;
-- WHERE PropertyAddress = '';
-- ORDER BY ParcelID;

SELECT
SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1) AS Address, 
SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress)) AS Address
FROM projects.nashvillehousing2;

ALTER TABLE projects.nashvillehousing2
ADD COLUMN PropertySplitAddress VARCHAR(255) AFTER PropertyAddress;

UPDATE projects.nashvillehousing2
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, POSITION(',' IN PropertyAddress) - 1);

ALTER TABLE projects.nashvillehousing2
ADD COLUMN PropertySplitCity VARCHAR(255) AFTER PropertySplitAddress;

UPDATE projects.nashvillehousing2
SET PropertySplitCity = SUBSTRING(PropertyAddress, POSITION(',' IN PropertyAddress) + 1, LENGTH(PropertyAddress));

-- OwnerAddress
SELECT OwnerAddress
FROM projects.nashvillehousing2;

SELECT
SUBSTRING_INDEX(OwnerAddress, ',', 1),
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
SUBSTRING_INDEX(OwnerAddress, ',', -1)
FROM projects.nashvillehousing2;

ALTER TABLE projects.nashvillehousing2
ADD COLUMN OwnerSplitAddress VARCHAR(255) AFTER OwnerAddress;

UPDATE projects.nashvillehousing2
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

ALTER TABLE projects.nashvillehousing2
ADD COLUMN OwnerSplitCity VARCHAR(255) AFTER OwnerSplitAddress;

UPDATE projects.nashvillehousing2
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);

ALTER TABLE projects.nashvillehousing2
ADD COLUMN OwnerSplitState VARCHAR(255) AFTER OwnerSplitCity;

UPDATE projects.nashvillehousing2
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress, ',', -1);


-------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM projects.nashvillehousing2
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END
FROM projects.nashvillehousing2;

UPDATE projects.nashvillehousing2
SET SoldAsVacant = CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
END;


-------------------------------------------------------------------

-- Remove Duplicates

SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
    ORDER BY UniqueID) row_num
FROM projects.nashvillehousing2
ORDER BY ParcelID;

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
    ORDER BY UniqueID) row_num
FROM projects.nashvillehousing2
ORDER BY ParcelID
)
DELETE
FROM projects.nashvillehousing2
USING projects.nashvillehousing2
JOIN RowNumCTE ON
	RowNumCTE.ParcelID = projects.nashvillehousing2.ParcelID
    AND RowNumCTE.PropertyAddress = projects.nashvillehousing2.PropertyAddress
    AND RowNumCTE.SalePrice = projects.nashvillehousing2.SalePrice
    AND RowNumCTE.SaleDate = projects.nashvillehousing2.SaleDate
    AND RowNumCTE.LegalReference = projects.nashvillehousing2.LegalReference
    AND RowNumCTE.UniqueID = projects.nashvillehousing2.UniqueID
WHERE row_num > 1;
-- ORDER BY PropertyAddress;

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
    PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
    ORDER BY UniqueID) row_num
FROM projects.nashvillehousing2
ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-------------------------------------------------------------------

-- Delete Unused Columns

SELECT *
FROM projects.nashvillehousing2;

ALTER TABLE projects.nashvillehousing2
DROP OwnerAddress, 
DROP PropertyAddress,
DROP TaxDistrict,
DROP SaleDate;

