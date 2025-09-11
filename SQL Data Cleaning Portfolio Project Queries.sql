/*
Cleaning Data in SQL Queries
*/

SELECT *
From [Data Cleaning Project]..NashvilleHousing


-------------------------------------------------------------------------------------------------------------------------------------


--Standardize Date Format

SELECT saleDateConverted, CONVERT(Date, SaleDate)
From [Data Cleaning Project]..NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


----------------------------------------------------------------------------------------------------------------------------------------


--Populate Property Address Data

SELECT *
From [Data Cleaning Project]..NashvilleHousing
--Where PropertyAddress is null
Order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Data Cleaning Project]..NashvilleHousing a
JOIN [Data Cleaning Project]..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From [Data Cleaning Project]..NashvilleHousing a
JOIN [Data Cleaning Project]..NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------------------


--Converting Address Into Individual Columns (Street, City, State)

SELECT PropertyAddress
From [Data Cleaning Project]..NashvilleHousing
--Where PropertyAddress is null
--Order by ParcelID

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)as Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))as Address

From [Data Cleaning Project]..NashvilleHousing

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update [Data Cleaning Project]..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update [Data Cleaning Project]..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


SELECT OwnerAddress
FROM [Data Cleaning Project]..NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM [Data Cleaning Project]..NashvilleHousing

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update [Data Cleaning Project]..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update [Data Cleaning Project]..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update [Data Cleaning Project]..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)


-------------------------------------------------------------------------------------------------------------------------------------------


--Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldasVacant), Count(SoldasVacant)
FROM [Data Cleaning Project]..NashvilleHousing
Group by SoldasVacant
Order by 2

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
When SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM [Data Cleaning Project]..NashvilleHousing

Update [Data Cleaning Project]..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
When SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END


-------------------------------------------------------------------------------------------------------------------------------------------


-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *, 
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
ORDER BY 
UniqueID) row_num

FROM [Data Cleaning Project]..NashvilleHousing
--ORDER BY ParcelID
)

--DELETE
--FROM RowNumCTE
--WHERE row_num > 1
----ORDER BY PropertyAddress

SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


--------------------------------------------------------------------------------------------------------------------------------------------


--Delete Unused Data

SELECT *
FROM [Data Cleaning Project]..NashvilleHousing

ALTER TABLE [Data Cleaning Project]..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
