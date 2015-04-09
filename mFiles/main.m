%% ETL HUMANA (Medicare Q1 2015)
%   Sohail Budhawani
%   Data Analyst
%   Marketing Productivity Group
%   1 Little West 12th Street
%   New York, NY 10014
%
%   Date & Version
%   January 13, 2015

clear all
clc

p='C:\Users\Sohail\Dropbox\Humana\Medicare Q1 2015\';

%% LOAD DATASTRUCT
load(strcat(p,'DEV\MATLAB\ETL\DATA\DATASTRUCT.mat'));

%% IMPORT BRAND
Brand = importBrand(p);

%% IMPORT DIGITAL
Digital = importDigital(p);

%% IMPORT DIRECT RESPONSE
DRLM  = importDirectResponse(p);

%% IMPORT LOCAL AGENCIES
Agency = importLocalAgencies(p);
Project1Agency = importLocalAgenciesUpdated(p);

%% IMPORT MEMBER ACITIVTY
AcquisitionRetention=importMemberActivity(p);

%% IMPORT WEBSITE
Website = importWebsite(p);

%% IMPORT CISION
Cision=importCision(p);







