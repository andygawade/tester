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
    const verificationLink = `http://localhost:5000/api/verify-email?token=${token}`;

    // Send verification email
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: user.email,
      subject: 'Verify your email',
      text: `Please verify your email by clicking the following link: ${verificationLink}`,
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
