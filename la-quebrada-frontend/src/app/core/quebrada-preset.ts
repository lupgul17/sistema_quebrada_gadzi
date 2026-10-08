import { definePreset } from '@primeuix/themes';
import Aura from '@primeuix/themes/aura';

/**
 * Preset PrimeNG de La Quebrada: modo oscuro con negros cálidos,
 * verde de la marca como color primario y controles tipo pill.
 */
export const QuebradaPreset = definePreset(Aura, {
  semantic: {
    // Escala verde construida desde el verde del logo (#344c2b = 800)
    primary: {
      50: '#f2f5ef',
      100: '#dfe8d8',
      200: '#c2d4b5',
      300: '#a0bb8c',
      400: '#84a56c',
      500: '#6a8c53',
      600: '#547043',
      700: '#415737',
      800: '#344c2b',
      900: '#283a21',
      950: '#172213',
    },
    formField: {
      borderRadius: '6px',
    },
    colorScheme: {
      light: {
        // Neutros cálidos claros (0 = tarjetas, 50 = canvas crema)
        surface: {
          0: '#ffffff',
          50: '#f7f4ee',
          100: '#efebe3',
          200: '#e2ddd3',
          300: '#cdc7bc',
          400: '#a8a39a',
          500: '#87837c',
          600: '#6a6660',
          700: '#4f4c48',
          800: '#363432',
          900: '#24221f',
          950: '#171615',
        },
        primary: {
          color: '{primary.600}',
          contrastColor: '#ffffff',
          hoverColor: '{primary.700}',
          activeColor: '{primary.800}',
        },
        highlight: {
          background: '{primary.50}',
          focusBackground: '{primary.100}',
          color: '{primary.800}',
          focusColor: '{primary.900}',
        },
        // Tarjetas y tablas en blanco translúcido sobre el fondo
        content: {
          background: 'rgba(255,255,255,0.6)',
          hoverBackground: 'rgba(255,255,255,0.85)',
          borderColor: 'rgba(0,0,0,0.06)',
        },
        formField: {
          background: 'rgba(255,255,255,0.75)',
          borderColor: 'rgba(0,0,0,0.12)',
          hoverBorderColor: 'rgba(0,0,0,0.24)',
        },
      },
      dark: {
        // Neutros cálidos (950 = canvas Onyx, 900 = Charcoal)
        surface: {
          0: '#ffffff',
          50: '#f5f4f2',
          100: '#e6e4e1',
          200: '#cfccc8',
          300: '#b0adaa',
          400: '#939292',
          500: '#6f6e6e',
          600: '#4a4847',
          700: '#323030',
          800: '#262828',
          900: '#171615',
          950: '#0f0d0d',
        },
        primary: {
          color: '{primary.400}',
          contrastColor: '#0f0d0d',
          hoverColor: '{primary.300}',
          activeColor: '{primary.200}',
        },
        highlight: {
          background: 'color-mix(in srgb, {primary.400}, transparent 84%)',
          focusBackground: 'color-mix(in srgb, {primary.400}, transparent 76%)',
          color: 'rgba(255,255,255,.87)',
          focusColor: 'rgba(255,255,255,.87)',
        },
        // Cada clave que se sobreescribe en light debe existir también aquí,
        // si no el valor claro se filtra al modo oscuro
        content: {
          background: '{surface.900}',
          hoverBackground: '{surface.800}',
          borderColor: 'rgba(255,255,255,0.08)',
        },
        formField: {
          background: 'rgba(255,255,255,0.03)',
          borderColor: 'rgba(255,255,255,0.12)',
          hoverBorderColor: 'rgba(255,255,255,0.24)',
        },
      },
    },
  },
  components: {
    button: {
      root: {
        borderRadius: '9999px',
        paddingX: '1.25rem',
      },
    },
    card: {
      root: {
        borderRadius: '16px',
      },
    },
    dialog: {
      root: {
        borderRadius: '16px',
      },
    },
    tag: {
      root: {
        borderRadius: '9999px',
      },
    },
    // Los paneles flotantes usan content.background, que en claro es translúcido (para las
    // tarjetas) y deja ver lo de atrás: aquí van sólidos en los dos temas
    datepicker: {
      colorScheme: {
        light: { panel: { background: '{surface.0}' } },
        dark: { panel: { background: '{surface.900}' } },
      },
    },
    menu: {
      colorScheme: {
        light: { root: { background: '{surface.0}' } },
        dark: { root: { background: '{surface.900}' } },
      },
    },
  },
});
