import Vue from 'vue';
import Vuex from 'vuex';

Vue.use(Vuex);

const state = {
  apiBaseURL: process.env.VUE_APP_API_BASE_URL,
  errors: [],
  runnableJobs: [],
  user: null
};

const getters = {
  errors: (state: any) => {
    return state.errors;
  },
  runnableJobs: (state: any) => {
    return state.runnableJobs;
  },
  user: (state: any) => {
    return state.user;
  }
};

const mutations = {
  logout: (state: any) => {
    state.user = null;
  },
  registerMe: (state: any, user: any) => {
    state.user = user;
  },
  cacheRunnableJobs: (state: any, runnableJobs: any) => {
    state.runnableJobs = runnableJobs;
  },
  reportError: (state: any, error: any) => {
    error.id = new Date().getTime();
    state.errors.push(error);
  },
  dismissError: (state: any, id: number) => {
    const indexOf = state.errors.findIndex((e: any) => e.id === id);
    if (indexOf > -1) {
      state.errors.splice(indexOf, 1);
    }
  }
};

export default new Vuex.Store({
  state,
  getters,
  mutations
});