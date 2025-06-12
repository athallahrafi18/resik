import express from 'express';
import { getRewardHistory } from '../controllers/reward_history_controller';

const router = express.Router();

router.get('/reward-history/:uid', getRewardHistory);

export default router;
