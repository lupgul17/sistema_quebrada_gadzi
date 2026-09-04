import { Component } from '@angular/core';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from 'primeng/tabs';
import { ComponentesMenuList } from '../componentes-menu-list/componentes-menu-list';
import { MenusList } from '../menus-list/menus-list';

@Component({
  selector: 'app-menu-page',
  standalone: true,
  imports: [Tabs, TabList, Tab, TabPanels, TabPanel, ComponentesMenuList, MenusList],
  templateUrl: './menu-page.html',
})
export class MenuPage {}