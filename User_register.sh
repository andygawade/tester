#!/bin/bash

# Step 1: Create project directory
PROJECT_NAME="user_registration_app"
mkdir $PROJECT_NAME
cd $PROJECT_NAME

# Step 2: Initialize a Node.js project (silent mode)
npm init -y

# Step 3: Install dependencies
npm install express ejs body-parser

# Step 4: Create necessary directories
mkdir -p public views

# Step 5: Create app.js
cat << 'EOF' > app.js
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();

// Middleware
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

// Set view engine to EJS
app.set('view engine', 'ejs');

// Render registration form
app.get('/register', (req, res) => {
  res.render('register');
});

// Handle form submission
app.post('/register', (req, res) => {
  const { name, email, password } = req.body;
  // Here you'd handle registration logic (e.g., save to a database)
  res.send(\`User \${name} registered with email \${email}\`);
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
EOF

# Step 6: Create EJS template (views/register.ejs)
cat << 'EOF' > views/register.ejs
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>User Registration</title>
  <link rel="stylesheet" href="/styles.css">
</head>
<body>
  <div class="container">
    <h1>User Registration</h1>
    <form action="/register" method="POST">
      <label for="name">Name:</label>
      <input type="text" id="name" name="name" required><br>

      <label for="email">Email:</label>
      <input type="email" id="email" name="email" required><br>

      <label for="password">Password:</label>
      <input type="password" id="password" name="password" required><br>

      <button type="submit">Register</button>
    </form>
  </div>
</body>
</html>
EOF

# Step 7: Create CSS file (public/styles.css)
cat << 'EOF' > public/styles.css
body {
  font-family: Arial, sans-serif;
  background-color: #f4f4f4;
  padding: 20px;
}

.container {
  width: 300px;
  margin: 0 auto;
}

input {
  margin-bottom: 10px;
  padding: 10px;
  width: 100%;
}

button {
  padding: 10px;
  width: 100%;
  background-color: #28a745;
  color: white;
  border: none;
  cursor: pointer;
}
EOF

# Step 8: Display completion message
echo "Node.js user registration app setup completed successfully!"

# Step 9: Instructions to run the app
echo "To run the app, execute the following commands:"
echo "cd $PROJECT_NAME"
echo "npm start"
