from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return f'Hello, please point your browser to http://LOAD_BALANCER_URL/sayhello/YOUR_NAME <br> and replace YOUR_NAME with, your name. <br> :)'

@app.route('/sayhello/<username>')
def greet(username):
    return f'Hello, {username}!'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=80)