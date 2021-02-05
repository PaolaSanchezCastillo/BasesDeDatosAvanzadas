import pyodbc
from flask import Flask, render_template, request, redirect, flash, url_for
import pandas as plt
import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd
from sqlalchemy import create_engine
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure

##Coneccion a la BD de AdventureWorks
direccion_servidor = 'PAOLA\SQLEXPRESS'
nombre_bd = 'AdventureWorks2017'
nombre_usuario = 'webservices'
password = '12060904Pa'
try:
    conexion = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' + 
                              direccion_servidor+';DATABASE='+nombre_bd+';UID='+nombre_usuario+';PWD=' + password)
    print("\n"*2)
    print("conexión exitosa")
    
except Exception as e:
    print("Ocurrió un error al conectar a SQL Server: ", e)



##Coneccion a la BD de Usuarios

servidor = 'PAOLA\SQLEXPRESS'
bd = 'Users'
usuario = 'webservices'
passw = '12060904Pa'
try:
    conexionUsuarios = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=' + 
                              servidor+';DATABASE='+bd+';UID='+usuario+';PWD=' + passw)
    print("\n"*2)
    print("conexión exitosa Usuarios")

    
    
except Exception as e:
    print("Ocurrió un error al conectar a SQL Server: ", e)


app = Flask(__name__)
app.secret_key = 'mysecretkey'
@app.route('/')
def Index():
    return render_template('Index.html')

@app.route('/Login', methods=['POST'])
def login():
    if request.method == 'POST':
        usuario = request.form['usuario']
        password = request.form['password']
        print(usuario)
        print(password)

        cursor = conexionUsuarios.cursor()
        sql = "exec searchUser ?, ?"
       ## sql = "SELECT * FROM Users WHERE [userName] =  ? AND psw =  ?"
        cursor.execute(sql, usuario, password)
        rows = cursor.fetchall()
        if rows: 
            for row in rows:
                if row[0] == 1: 
                    return redirect(url_for('Crud'))
        flash('Error en usuario o contraseña, favor de verificar.')
    return redirect(url_for('Index'))       


@app.route('/menuCrud')
def Crud():
    return render_template('menuMovimientos.html')

@app.route('/productos')
def read_products():
    cursor = conexion.cursor()
    sql = "SELECT top 100  * FROM Production.Product order by ListPrice desc"
    cursor.execute(sql)
    data = cursor.fetchall()
    print(data)
    return render_template('products.html', productos = data)


@app.route('/editarproductos/<string:id>')
def edit_products(id):
    cursor = conexion.cursor()
    sql = "SELECT * FROM Production.Product WHERE ProductID=  ?"
    cursor.execute(sql, id)
    data = cursor.fetchall()
    print(data)
    return render_template('editproduct.html', product = data[0])


@app.route('/update/<id>' , methods=['POST'])
def updateProduct(id):
    name = request.form['Name']
    listPrice = request.form['ListPrice']
    productNumber = request.form['ProductNumber']
    size = request.form['Size']
    cursor = conexion.cursor()
    sql = "UPDATE Production.Product  set [Name] = ?, [ProductNumber] = ? , [ListPrice] = ? , [Size] = ?    WHERE ProductID=  ?"
    cursor.execute(sql, name, productNumber, listPrice, size, id )
    flash("Producto Actualizado Correctamente")
    return redirect(url_for('read_products'))


@app.route('/crearProducto' , methods=['POST'])
def createProduct():
    name = request.form['Name']
    listPrice = request.form['ListPrice']
    productNumber = request.form['ProductNumber']
    size = request.form['Size']
    safetyStockLevel = 800
    cursor = conexion.cursor()
    
    sql = "INSERT INTO  Production.Product ([Name],[ProductNumber],[ListPrice], [Size], [SafetyStockLevel]) values (?, ?, ? , ? , ?) "
    cursor.execute(sql, name, productNumber, listPrice, size , safetyStockLevel)
    flash("Producto Añadido Correctamente")
    return redirect(url_for('read_products'))

@app.route('/nuevo' )
def nuevo():
    return render_template('nuevoproducto.html')


if __name__ == '__main__':  
    app.run(port = 3000, debug = True)