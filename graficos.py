import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd
import pyodbc

from flask import Flask, render_template, request, redirect, flash, url_for

app = dash.Dash(__name__)

servidor = 'PAOLA\SQLEXPRESS'
bd = 'AdventureWorks2017'
usuario = 'analytics'
passw = '12060904Pa'
conexionAnalitics = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' + 
                                servidor+';DATABASE='+bd+';UID='+usuario+';PWD=' + passw)
print("\n"*2)
print("conexión exitosa Usuarios")




cursorAnalitics = conexionAnalitics.cursor()
sql = """SELECT CONCAT([FirstName],' ', [LastName]) as FullName,
            [SalesQuota],
            [SalesYTD]
        FROM [Sales].[vSalesPerson]"""
        ##df = plt.read_sql(sql, conexionAnalitics)
    
df = pd.read_sql(sql, conexionAnalitics)


salesFigure = px.bar(df, x="SalesYTD", y="FullName", color="SalesQuota", barmode="group")
quotaFigure = px.bar(df, x="SalesQuota", y="FullName", color="SalesQuota", barmode="group")

app.layout = html.Div(children=[
    html.H1(children='Adventure Works Sales Report'),

    html.Div(children='''
        YTD Sales by Individual.
    '''),

    dcc.Graph(
        id='sales-graph',
        figure=salesFigure
    ),

    html.Div(children='''
        Quota by Individual.
    '''),

    dcc.Graph(
        id='quota-graph',
        figure=quotaFigure
    )
])

if __name__ == '__main__':
    app.run_server(debug=True)