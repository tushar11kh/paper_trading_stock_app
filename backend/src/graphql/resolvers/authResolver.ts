import { AuthService } from '../../services/authService';

export const authResolvers = {
  Mutation: {
    register: async (_: unknown, { input }: { input: { email: string; password: string } }) => {
      const user = await AuthService.register(input.email, input.password);
      const token = await AuthService.login(input.email, input.password);
      return {
        token,
        user
      };
    },
    login: async (_: unknown, { input }: { input: { email: string; password: string } }) => {
      const token = await AuthService.login(input.email, input.password);
      const user = await AuthService.verifyToken(token);
      return {
        token,
        user
      };
    }
  }
}; 