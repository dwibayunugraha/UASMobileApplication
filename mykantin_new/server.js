const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const cors = require('cors');

// Inisialisasi aplikasi Express
const app = express();
const port = 3000;

// Middleware untuk parsing JSON
app.use(bodyParser.json());

// Middleware CORS untuk mengizinkan permintaan dari domain lain
app.use(cors());

// Midtrans Server Key (sandbox)
const SERVER_KEY = 'SB-Mid-server-8055QNA56pEPx4G8aywKOWh4';

// Route untuk mendapatkan Snap Token
app.post('/get-snap-token', async (req, res) => {
  // Log request body untuk debugging
  console.log('Received request:', req.body);

  try {
    // Data yang diterima dari Flutter
    const { order_id, gross_amount, first_name, email, phone } = req.body;

    // Format data sesuai kebutuhan Midtrans
    const transactionData = {
      transaction_details: {
        order_id: order_id,
        gross_amount: gross_amount,
      },
      customer_details: {
        first_name: first_name,
        email: email,
        phone: phone,
      },
      credit_card: {
        secure: true,
      },
    };

    // Kirim permintaan ke Midtrans Snap API
    const response = await axios.post(
      'https://app.sandbox.midtrans.com/snap/v1/transactions',
      transactionData,
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Basic ${Buffer.from(SERVER_KEY + ':').toString('base64')}`,
        },
      }
    );

    // Log response dari Midtrans API untuk debugging
    console.log('Midtrans response:', response.data);

    // Berhasil mendapatkan Snap Token
    res.status(200).json({ token: response.data.token });
  } catch (error) {
    // Tangani error dan log error yang terjadi
    console.error('Error getting Snap token:', error.message);
    res.status(500).json({ error: 'Failed to get Snap token', details: error.message });
  }
});

// Jalankan server
app.listen(port, () => {
  console.log(`Server berjalan di http://localhost:${port}`);
});
