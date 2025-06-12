import express from 'express';
import { lookupBarcode } from '../controllers/barcodeController';
import { wrapHandler } from '../utils/wrapHandler';

const router = express.Router();

router.post('/barcode', wrapHandler(lookupBarcode));

export default router;
