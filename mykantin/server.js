const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const axios = require('axios');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Konfigurasi Midtrans
const MIDTRANS_SERVER_KEY = 'SB-Mid-server-8055QNA56pEPx4G8aywKOWh4'; // Ganti dengan Server Key Midtrans kamu
const MIDTRANS_API_URL = 'https://app.sandbox.midtrans.com/snap/v1/transactions';

// Route untuk membuat pembayaran Midtrans
app.post('/create-payment', async (req, res) => {
  console.log('Request Body:', req.body);

  const { amount, order_id, customer_details } = req.body;

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Basic ${Buffer.from(MIDTRANS_SERVER_KEY).toString('base64')}`
  };

  const data = {
    transaction_details: {
      order_id: order_id,
      gross_amount: amount
    },
    credit_card: {
      secure: true
    },
    customer_details: customer_details
  };

  try {
    const response = await axios.post(MIDTRANS_API_URL, data, { headers });
    console.log('Midtrans response:', response.data);

    // Mengembalikan URL untuk redirect ke aplikasi Midtrans
    res.json({
      status: 'success',
      redirect_url: response.data.redirect_url
    });
  } catch (error) {
    console.error('Error processing payment:', error.response ? error.response.data : error.message);
    res.status(500).json({
      status: 'error',
      message: 'Failed to process payment with Midtrans.'
    });
  }
});

// Jalankan server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
