import express from 'express';
import { getAllUsers, deleteUser, getUserById, updateUser } from '../controllers/user_controller';

const router = express.Router();

router.get("/users", getAllUsers);
router.get('/users/:id', getUserById);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);

export default router;
