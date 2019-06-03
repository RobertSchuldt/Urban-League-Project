# -*- coding: utf-8 -*-
"""
Created on Thu Apr 11 17:45:54 2019
@author: Robert Schuldt
@email: rschuldt@uams.edu
"""


import datetime
import requests
import pandas as pd
import json
import os 

ts = datetime.datetime.now().isoformat()

white = "B27001A_008E,B27001A_009E,B27001A_010E,B27001A_011E,B27001A_012E,B27001A_013E,B27001A_014E,B27001A_015E,B27001A_016E"
black = "B27001B_008E,B27001B_009E,B27001B_010E,B27001B_011E,B27001B_012E,B27001B_013E,B27001B_014E,B27001B_015E,B27001B_016E"
state = "01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50"

 #Creating a list of the actual variable names that we are interested in 

def acs_pull(word):
    ''' Identifying the variable I am interested in regarding African American 
        insurance rates this function grabs from a specified year and appends to an existing dataframe '''

    api = "https://api.census.gov/data/" + str(word)+ "/acs/acs1?get=NAME,"+str(white)+","+str(black)+"&for=state:*&key=****"

    print('Requesting data from the American Communities Survey API')
    
    acs_data = requests.get(api)

    if (acs_data.status_code != 200):
        print('Error detected receiving (status code: ' + str(acs_data.status_code) + ')' )
    else:
        print('Sucessful request from American Communities Survey')
    
    content = acs_data.json()
    print("Data converted to JSON formatting from ACS")
    headers= [ 'State','Total_White_19_25' ,'Total_White_Insur_19_25','Total_White_UnInsur_19_25','Total_White_26_34' ,'Total_White_Insur_26_34','Total_White_UnInsur_26_34',
              'Total_White_35_44' ,'Total_White_Insur_35_44','Total_White_UnInsur_35_44', 'Total_AA_19_25' ,'Total_AA_Insur_19_25','Total_AA_UnInsur_19_25','Total_AA_26_34' ,
              'Total_AA_Insur_26_34','Total_AA_UnInsur_26_34','Total_AA_35_44' ,'Total_AA_Insur_35_44','Total_AA_UnInsur_35_44', 'state']

    #I am adding the list of headers that will actually define what the different variables are

    df= pd.DataFrame(data=content, columns = headers)
    df['Year']=word
    
    insur= df.drop([0])
    
    print('Pandas dataframe created at ' + str(ts))
    
    if not os.path.isfile('Z:\\DATA\\Urban League Project\\Data\\insurancedata.csv'):
        insur.to_csv('Z:\\DATA\\Urban League Project\\Data\\insurancedata.csv', index= True, header='headers' )
    else:
        insur.to_csv('Z:\\DATA\\Urban League Project\\Data\\insurancedata.csv', mode= 'a' , header=False )
    print('Appended csv with year ' + str(word) +' to main file at ' + str(ts))


acs_pull(2017)
acs_pull(2016)
acs_pull(2015)
acs_pull(2014)
acs_pull(2013)
acs_pull(2012)
acs_pull(2011)