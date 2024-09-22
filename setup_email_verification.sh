#!/bin/bash

# Set up project directory
PROJECT_DIR="email-verification"
echo "Setting up project in '$PROJECT_DIR'..."
mkdir $PROJECT_DIR
cd $PROJECT_DIR

# Initialize Node.js project
echo "Initializing Node.js project..."
npm init -y

# Install required dependencies
echo "Installing dependencies..."
npm install express mongoose bcryptjs body-parser nodemailer jsonwebtoken dotenv

# Create necessary folders
echo "Creating folders..."
mkdir -p models routes config

# Create User model
echo "Creating User model..."
cat > models/User.js <<EOL
const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 6,
  },
  isVerified: {
    type: Boolean,
    default: false, // User is not verified by default
  },
  date: {
    type: Date,
    default: Date.now,
  },
});

const User = mongoose.model('User', UserSchema);
module.exports = User;
EOL

# Create email configuration with Nodemailer
echo "Creating email configuration..."
cat > config/emailConfig.js <<EOL
const nodemailer = require('nodemailer');
require('dotenv').config();

// Create a transporter for sending emails
const transporter = nodemailer.createTransport({
  service: 'Gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

module.exports = transporter;
EOL

# Create .env file
echo "Creating .env file..."
cat > .env <<EOL
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-email-password
JWT_SECRET=your_jwt_secret_key
EOL

# Create authentication routes for registration and email verification
echo "Creating authentication routes..."
cat > routes/auth.js <<EOL
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const transporter = require('../config/emailConfig');
require('dotenv').config();

const router = express.Router();

// Secret key for JWT (from .env)
const JWT_SECRET = process.env.JWT_SECRET;

// @route   POST /api/register
// @desc    Register user with email and password
router.post('/register', async (req, res) => {
  const { email, password } = req.body;

  // Simple validation
  if (!email || !password) {
    return res.status(400).json({ msg: 'Please enter all fields' });
  }

  try {
    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ msg: 'User already exists' });
    }

    // Create new user instance
    user = new User({
      email,
      password,
    });

    // Hash password before saving
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);

    // Save user to the database
    await user.save();

    // Generate JWT token for email verification
    const token = jwt.sign({ id: user._id, email: user.email }, JWT_SECRET, { expiresIn: '1h' });

    // Create verification link
    const verificationLink = \`http://localhost:5000/api/verify-email?token=\${token}\`;

    // Send verification email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: user.email,
      subject: 'Verify your email',
      text: \`Please verify your email by clicking the following link: \${verificationLink}\`,
    };

    transporter.sendMail(mailOptions, (err, info) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ msg: 'Failed to send verification email' });
      }
      res.status(201).json({ msg: 'User registered. Please check your email to verify your account.' });
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

// @route   GET /api/verify-email
// @desc    Verify the email using token
router.get('/verify-email', async (req, res) => {
  const token = req.query.token;

  // Check if token is valid
  if (!token) {
    return res.status(400).json({ msg: 'Invalid token' });
  }

  try {
    // Verify the JWT token
    const decoded = jwt.verify(token, JWT_SECRET);
    const userId = decoded.id;

    // Find the user by ID
    const user = await User.findById(userId);

    if (!user) {
      return res.status(400).json({ msg: 'User not found' });
    }

    if (user.isVerified) {
      return res.status(400).json({ msg: 'User is already verified' });
    }

    // Mark user as verified
    user.isVerified = true;
    await user.save();

    res.status(200).json({ msg: 'Email successfully verified' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error');
  }
});

module.exports = router;
EOL

# Create main server file
echo "Creating main server file..."
cat > server.js <<EOL
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const authRoutes = require('./routes/auth');
require('dotenv').config();

// Initialize the app
const app = express();

// Middleware
app.use(bodyParser.json()); // for parsing application/json

// Connect to MongoDB
mongoose.connect('mongodb://mongo:27017/yourdbname', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  useCreateIndex: true,
})
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

// Use routes
app.use('/api', authRoutes);

// Listen on port
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT}\`));
EOL

# Create Dockerfile
echo "Creating Dockerfile..."
cat > Dockerfile <<EOL
# Use an official Node.js image as the base image
FROM node:14

# Set the working directory
WORKDIR /app

# Copy the package.json and package-lock.json
COPY package*.json ./

# Install the dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Define the command to run the app
CMD ["npm", "start"]
EOL

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml <<EOL
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    depends_on:
      - mongo
    environment:
      - MONGO_URI=mongodb://mongo:27017/yourdbname

  mongo:
    image: mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

volumes:
  mongo-data:
EOL

# Completion message
echo "Project setup complete. Run 'docker-compose up' to start the application and MongoDB services."
