export interface User {
  uid: string;
  username: string;
  email: string;
  phone: string;
  password: string;
  role: 'admin' | 'user';
  createdAt?: Date; // opsional, bisa auto generate
}
