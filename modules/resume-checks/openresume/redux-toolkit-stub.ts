// The parser reads one constant (initialFeaturedSkills) from OpenResume's Redux slice module; the slice itself is never
// used, so an inert createSlice stands in for bundling Redux Toolkit.
export const createSlice = (): { actions: Record<string, never> } => ({ actions: {} });
