import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';
import Header from './Header';

const Layout = () => {
    return (
        <div className="flex h-screen bg-gray-50 dark:bg-dark-bg font-sans transition-colors duration-200">
            <Sidebar />
            <div className="flex-1 flex flex-col min-h-screen mr-64 transition-all duration-300">
                <Header />
                <main className="flex-1 p-8 mt-16 bg-gray-50/50 dark:bg-dark-bg/50">
                    <div className="max-w-7xl mx-auto">
                        <Outlet />
                    </div>
                </main>
            </div>
        </div>
    );
};

export default Layout;
